import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';
import 'package:core/api/api_service.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:main_login/main.dart' as main_login;
import 'main.dart' as app;
import 'dashboard.dart';


class PhotoEntry {
  final int id;
  final String photoId;
  final String title;
  final String category;
  final String description;
  final DateTime date;
  final String photographer;
  final String location;
  final String emoji;
  bool isFavorite;
  List<Uint8List> images;

  PhotoEntry({
    required this.id,
    required this.photoId,
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    required this.photographer,
    required this.location,
    required this.emoji,
    this.isFavorite = false,
    List<Uint8List>? images,
  }) : images = images ?? [];
}

// ... existing code ...



class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final List<PhotoEntry> _allPhotos = [];

  late List<PhotoEntry> _visiblePhotos;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();
  final _photoIdController = TextEditingController(); // Added Photo ID controller
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _photographerController = TextEditingController();
  final _locationController = TextEditingController();

  String? _newCategory;
  DateTime? _newDate;
  List<Uint8List> _selectedImageBytes = [];

  String _searchQuery = '';
  String? _categoryFilter;
  String? _dateFilter;
  bool _isLoading = true;
  
  // -- Helper Widgets --

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C757D), Color(0xFF495057)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF495057).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.arrow_back, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    _visiblePhotos = List<PhotoEntry>.from(_allPhotos);
    _fetchGalleries();
  }

  @override
  void dispose() {
    _photoIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _photographerController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isError ? 'Error' : 'Notification'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _filterPhotos() {
    setState(() {
      _visiblePhotos = _allPhotos.where((photo) {
        final matchesSearch = _searchQuery.isEmpty ||
            photo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            photo.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            photo.photographer.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory =
            _categoryFilter == null || photo.category == _categoryFilter;

        bool matchesDate = true;
        if (_dateFilter != null) {
          final now = DateTime.now();
          switch (_dateFilter) {
            case 'today':
              matchesDate = photo.date.year == now.year &&
                  photo.date.month == now.month &&
                  photo.date.day == now.day;
              break;
            case 'week':
              final weekAgo = now.subtract(const Duration(days: 7));
              matchesDate = photo.date.isAfter(weekAgo) || photo.date.isAtSameMomentAs(weekAgo);
              break;
            case 'month':
              matchesDate = photo.date.year == now.year &&
                  photo.date.month == now.month;
              break;
            case 'year':
              matchesDate = photo.date.year == now.year;
              break;
          }
        }

        return matchesSearch && matchesCategory && matchesDate;
      }).toList();
    });
  }

  Map<String, int> _stats() {
    final total = _allPhotos.length;
    final now = DateTime.now();
    final thisMonth = _allPhotos
        .where((photo) =>
            photo.date.year == now.year && photo.date.month == now.month)
        .length;
    final events = _allPhotos
        .where((photo) => photo.category == 'Events')
        .length;
    final activities = _allPhotos
        .where((photo) => photo.category == 'Activities')
        .length;

    return {
      'total': total,
      'month': thisMonth,
      'events': events,
      'activities': activities,
    };
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _newDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _newDate = date;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    
    final List<Uint8List> imageBytesList = [];
    for (var image in picked) {
      final bytes = await image.readAsBytes();
      imageBytesList.add(bytes);
    }
    
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = imageBytesList;
    });
  }

  Future<void> _fetchGalleries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService().get('/management-admin/galleries/');
      
      if (response.success && response.data != null) {
        // Handle both paginated and non-paginated responses
        List<dynamic> galleriesJson;
        
        if (response.data is Map && response.data.containsKey('results')) {
          // Paginated response
          galleriesJson = response.data['results'] as List<dynamic>;
        } else if (response.data is List) {
          // Direct array response
          galleriesJson = response.data as List<dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }
        
        final List<PhotoEntry> fetchedPhotos = [];
        
        for (var galleryJson in galleriesJson) {
          // Fetch images for this gallery
          List<Uint8List> imageBytes = [];
          if (galleryJson['images'] != null && galleryJson['images'] is List) {
            for (var imageData in galleryJson['images']) {
              try {
                // Get the image URL from the backend
                String imageUrl = imageData['image'];
                
                // If it's a relative URL, make it absolute
                if (!imageUrl.startsWith('http')) {
                  // Assuming backend is at localhost:8000
                  imageUrl = 'http://localhost:8000$imageUrl';
                }
                
                // Fetch the image bytes using http package
                final imageResponse = await http.get(Uri.parse(imageUrl));
                if (imageResponse.statusCode == 200) {
                  imageBytes.add(imageResponse.bodyBytes);
                }
              } catch (e) {
                print('Error loading image: $e');
                // Continue with other images even if one fails
              }
            }
          }
          
          // Parse the gallery data
          final photoEntry = PhotoEntry(
            id: galleryJson['id'] ?? 0,
            photoId: galleryJson['photo_id'] ?? '',
            title: galleryJson['title'] ?? '',
            category: galleryJson['category'] ?? 'Other',
            description: galleryJson['description'] ?? '',
            date: galleryJson['date'] != null 
                ? DateTime.parse(galleryJson['date']) 
                : DateTime.now(),
            photographer: galleryJson['photographer'] ?? '',
            location: galleryJson['location'] ?? '',
            emoji: galleryJson['emoji'] ?? '📷',
            isFavorite: galleryJson['is_favorite'] ?? false,
            images: imageBytes,
          );
          
          fetchedPhotos.add(photoEntry);
        }
        
        setState(() {
          _allPhotos.clear();
          _allPhotos.addAll(fetchedPhotos);
          _filterPhotos();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showNotification('Failed to load galleries: ${response.error ?? "Unknown error"}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showNotification('Error loading galleries: $e', isError: true);
      }
    }
  }


  Future<void> _addPhoto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newCategory == null || _newDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Generate or use provided Photo ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String photoId = _photoIdController.text.trim();
    if (photoId.isEmpty) {
      final randomId = (timestamp % 10000) + 1000;
      photoId = 'PID-$timestamp-$randomId';
    }

    // Prepare data directly for API
    final galleryData = {
      'photo_id': photoId,
      'title': _titleController.text.trim(),
      'category': _newCategory!,
      'description': _descriptionController.text.trim(),
      'date': _newDate!.toIso8601String().split('T')[0], // YYYY-MM-DD
      'photographer': _photographerController.text.trim(),
      'location': _locationController.text.trim(),
      'emoji': '📷',
      'is_favorite': false,
    };

    try {
      // 1. Create Gallery Entry
      final response = await ApiService().post(
        '/management-admin/galleries/',
        body: galleryData,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to create gallery');
      }

      final createdGallery = response.data;
      final galleryId = createdGallery['id']; // ID from DB

      // 2. Upload Images if selected
      if (_selectedImageBytes.isNotEmpty) {
        int uploadedCount = 0;
        int failedCount = 0;
        
        for (int i = 0; i < _selectedImageBytes.length; i++) {
          try {
            final imageBytes = _selectedImageBytes[i];
            final uploadResponse = await ApiService().uploadFile(
              '/management-admin/galleries/$galleryId/upload-image/',
              fileBytes: imageBytes,
              fileName: 'image_${timestamp}_$i.jpg',
              fieldName: 'image',
              additionalFields: {
                'caption': i == 0 ? 'main image' : 'image ${i + 1}',
              }
            );

            if (uploadResponse.success) {
              uploadedCount++;
            } else {
              failedCount++;
            }
          } catch (e) {
            failedCount++;
            print('Error uploading image $i: $e');
          }
        }
        
        if (failedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gallery created. $uploadedCount images uploaded, $failedCount failed.')),
          );
        }
      }

      // Update UI
      final images = _selectedImageBytes.isNotEmpty ? _selectedImageBytes : <Uint8List>[];
      final photo = PhotoEntry(
        id: galleryId, // Use DB ID
        photoId: photoId,
        title: _titleController.text.trim(),
        category: _newCategory!,
        description: _descriptionController.text.trim(),
        date: _newDate!,
        photographer: _photographerController.text.trim(),
        location: _locationController.text.trim(),
        emoji: '📷',
        images: images,
      );

      setState(() {
        _allPhotos.insert(0, photo);
        _filterPhotos();
      });

      _formKey.currentState!.reset();
      _photoIdController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _photographerController.clear();
      _locationController.clear();
      setState(() {
        _newCategory = null;
        _newDate = null;
        _selectedImageBytes = [];
      });

      _showNotification('Photo added successfully!');

    } catch (e) {
      _showNotification('Error adding photo: $e', isError: true);
    }
  }

  void _toggleFavorite(PhotoEntry photo) {
    setState(() {
      photo.isFavorite = !photo.isFavorite;
    });
  }

  void _deletePhoto(PhotoEntry photo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Text('Are you sure you want to delete "${photo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allPhotos.remove(photo);
                _filterPhotos();
              });
              _showNotification('Photo deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, List<Uint8List> images, int initialIndex) {
    final pageController = PageController(initialPage: initialIndex);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.memory(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 20,
              left: 20,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImages(PhotoEntry photo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${photo.images.length} image${photo.images.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ApiService().userRole != 'financial')
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery);
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            if (!mounted) return;
                            
                            // Upload to backend
                            try {
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              final uploadResponse = await ApiService().uploadFile(
                                '/management-admin/galleries/${photo.id}/upload-image/',
                                fileBytes: bytes,
                                fileName: 'image_$timestamp.jpg',
                                fieldName: 'image',
                                additionalFields: {
                                  'caption': 'additional image',
                                }
                              );

                              if (uploadResponse.success) {
                                setState(() {
                                  photo.images.add(bytes);
                                });
                                setDialogState(() {});
                                _showNotification('Image uploaded successfully!');
                              } else {
                                _showNotification('Upload failed: ${uploadResponse.error}', isError: true);
                              }
                            } catch (e) {
                              _showNotification('Error uploading image: $e', isError: true);
                            }
                          },
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                if (photo.images.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No images uploaded yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: photo.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onDoubleTap: () {
                              _showFullImage(context, photo.images, index);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                photo.images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final stats = _stats();

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 1100;
        return Scaffold(
          key: _scaffoldKey,
          drawer: showSidebar
              ? null
              : Drawer(
                  child: SizedBox(
                    width: 280,
                    child: ManagementSidebar(gradient: gradient, activeRoute: '/gallery'),
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar) ManagementSidebar(gradient: gradient, activeRoute: '/gallery'),
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F6FA),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TOP HEADER ---
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Photo Gallery',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Manage school photo entries and gallery collections',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildUserInfo(),
                                const SizedBox(width: 20),
                                _buildBackButton(),
                              ],
                            ),
                          ),
                          _StatsOverview(stats: stats),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, inner) {
                              final stacked = inner.maxWidth < 1100;
                              return Flex(
                                mainAxisSize: MainAxisSize.min,
                                direction:
                                    stacked ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: ApiService().userRole == 'financial' 
                                      ? const SizedBox.shrink() 
                                      : _AddPhotoSection(
                                          formKey: _formKey,
                                          photoIdController: _photoIdController,
                                          titleController: _titleController,
                                          descriptionController:
                                              _descriptionController,
                                          photographerController:
                                              _photographerController,
                                          locationController: _locationController,
                                          category: _newCategory,
                                          onCategoryChanged: (value) =>
                                              setState(() => _newCategory = value),
                                          date: _newDate,
                                          onPickDate: _pickDate,
                                          selectedImageBytes: _selectedImageBytes,
                                          onPickPhoto: _pickPhoto,
                                          onSubmit: _addPhoto,
                                        ),
                                  ),
                                  SizedBox(
                                    width: stacked ? 0 : 24,
                                    height: stacked ? 24 : 0,
                                  ),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: _SearchFilterSection(
                                      searchQuery: _searchQuery,
                                      onSearchChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                        _filterPhotos();
                                      },
                                      categoryFilter: _categoryFilter,
                                      onCategoryChanged: (value) {
                                        setState(() {
                                          _categoryFilter = value;
                                        });
                                        _filterPhotos();
                                      },
                                      dateFilter: _dateFilter,
                                      onDateChanged: (value) {
                                        setState(() {
                                          _dateFilter = value;
                                        });
                                        _filterPhotos();
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading galleries...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _GalleryGrid(
                              photos: _visiblePhotos,
                              onToggleFavorite: _toggleFavorite,
                              onDelete: _deletePhoto,
                              onViewImages: (photo) => _viewImages(photo),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



class _StatsOverview extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: '🖼️',
          label: 'Total Albums',
          value: stats['total'].toString(),
          color: const Color(0xFF667EEA),
        ),
        _StatCard(
          icon: '📅',
          label: 'This Month',
          value: stats['month'].toString(),
          color: Colors.green,
        ),
        _StatCard(
          icon: '🎭',
          label: 'Events',
          value: stats['events'].toString(),
          color: Colors.orange,
        ),
        _StatCard(
          icon: '⚽',
          label: 'Activities',
          value: stats['activities'].toString(),
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 40, color: color)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController photoIdController;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController photographerController;
  final TextEditingController locationController;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final DateTime? date;
  final VoidCallback onPickDate;
  final List<Uint8List> selectedImageBytes;
  final Future<void> Function() onPickPhoto;
  final VoidCallback onSubmit;

  const _AddPhotoSection({
    required this.formKey,
    required this.photoIdController,
    required this.titleController,
    required this.descriptionController,
    required this.photographerController,
    required this.locationController,
    required this.category,
    required this.onCategoryChanged,
    required this.date,
    required this.onPickDate,
    required this.selectedImageBytes,
    required this.onPickPhoto,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text('➕', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Text(
                  'Add New Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: onPickPhoto,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedImageBytes.isNotEmpty
                      ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: selectedImageBytes.map((imageBytes) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                imageBytes,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                        )
                      : Column(
                          children: [
                            const Text(
                              '📷',
                              style: TextStyle(fontSize: 40),
                            ),
                            const SizedBox(height: 10),
                            const Text('Click to upload photos'),
                            const SizedBox(height: 5),
                            Text(
                              'Select multiple images (JPG, PNG, GIF)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: photoIdController,
                    decoration: InputDecoration(
                      labelText: 'Photo ID (Optional)',
                      hintText: 'Leave empty to auto-generate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Photo Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter title' : null,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Events', child: Text('School Events')),
                            DropdownMenuItem(
                                value: 'Activities',
                                child: Text('Extra Curricular')),
                            DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                            DropdownMenuItem(
                                value: 'Academic', child: Text('Academic')),
                            DropdownMenuItem(
                                value: 'Cultural', child: Text('Cultural')),
                            DropdownMenuItem(
                                value: 'Awards',
                                child: Text('Awards & Recognition')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: onCategoryChanged,
                          validator: (value) =>
                              value == null ? 'Please select category' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: onPickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date Taken',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              date == null
                                  ? 'Select date'
                                  : DateFormat('yyyy-MM-dd').format(date!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the photo, event, or memory...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: photographerController,
                          decoration: InputDecoration(
                            labelText: 'Photographer',
                            hintText: 'Who took the photo?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            hintText: 'Where was it taken?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Photo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterSection extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;
  final String? dateFilter;
  final ValueChanged<String?> onDateChanged;

  const _SearchFilterSection({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.dateFilter,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text('🔍', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                'Search & Filter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: TextEditingController(text: searchQuery)
              ..selection = TextSelection.collapsed(offset: searchQuery.length),
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search photos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: categoryFilter,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'Events', child: Text('Events')),
                    DropdownMenuItem(value: 'Activities', child: Text('Activities')),
                    DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                    DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                    DropdownMenuItem(value: 'Awards', child: Text('Awards')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: dateFilter,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Dates')),
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                    DropdownMenuItem(value: 'year', child: Text('This Year')),
                  ],
                  onChanged: onDateChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<PhotoEntry> photos;
  final ValueChanged<PhotoEntry> onToggleFavorite;
  final ValueChanged<PhotoEntry> onDelete;
  final ValueChanged<PhotoEntry> onViewImages;

  const _GalleryGrid({
    required this.photos,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onViewImages,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Text(
                'No photos found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'Add some photos to get started!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 700
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.70,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _PhotoCard(
            photo: photos[index],
            onToggleFavorite: () => onToggleFavorite(photos[index]),
            onDelete: () => onDelete(photos[index]),
            onViewImages: () => onViewImages(photos[index]),
          ),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoEntry photo;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onViewImages;

  const _PhotoCard({
    required this.photo,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onViewImages,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM dd, yyyy');
    return GestureDetector(
      onDoubleTap: onViewImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: photo.images.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      )
                    : null,
                color: photo.images.isEmpty ? null : Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  if (photo.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.memory(
                        photo.images.first,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        photo.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      photo.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: Icon(
                      photo.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: photo.isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
                if (ApiService().userRole != 'financial')
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: onDelete,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  photo.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📅 ${formatter.format(photo.date)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        photo.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📸 ${photo.photographer}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '📍 ${photo.location}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}



// Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool drawRightBorder;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.drawRightBorder = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final radius = drawRightBorder
        ? BorderRadius.zero
        : BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border(
                right: drawRightBorder
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                    : BorderSide.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
