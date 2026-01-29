import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:core/api/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/api/endpoints.dart';

void main() => runApp(
  const MaterialApp(
    home: SchoolGalleryPage(),
    debugShowCheckedModeBanner: false,
  ),
);

// Updated data model to match backend Gallery structure
class GalleryPhoto {
  final int id;
  final String photoId;
  final String title;
  final String category;
  final DateTime date;
  final String description;
  final String photographer;
  final String location;
  final String emoji;
  final bool isFavorite;
  final List<String> imageUrls; // URLs from backend

  GalleryPhoto({
    required this.id,
    required this.photoId,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.photographer,
    required this.location,
    required this.emoji,
    this.isFavorite = false,
    this.imageUrls = const [],
  });
}

class SchoolGalleryPage extends StatefulWidget {
  const SchoolGalleryPage({super.key});

  @override
  State<SchoolGalleryPage> createState() => _SchoolGalleryPageState();
}

class _SchoolGalleryPageState extends State<SchoolGalleryPage> {
  List<GalleryPhoto> photos = [];
  String categoryFilter = 'all';
  String yearFilter = 'all';
  String searchTerm = '';
  String sortCriteria = 'date_desc'; // Default: newest first
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  @override
  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      
      // Fetch galleries
      final galleryResponse = await apiService.get('/management-admin/galleries/');
      
      final List<GalleryPhoto> fetchedItems = [];
      
      // 1. Process Galleries
      if (galleryResponse.success && galleryResponse.data != null) {
        List<dynamic> galleriesJson = _parseResponseList(galleryResponse.data);
        
        for (var galleryJson in galleriesJson) {
          List<String> imageUrls = [];
          if (galleryJson['images'] != null && galleryJson['images'] is List) {
            for (var imageData in galleryJson['images']) {
              String imageUrl = imageData['image'];
              // Make relative URLs absolute
              if (!imageUrl.startsWith('http')) {
                imageUrl = 'http://localhost:8000$imageUrl';
              }
              imageUrls.add(imageUrl);
            }
          }
          
          fetchedItems.add(GalleryPhoto(
            id: galleryJson['id'] ?? 0,
            photoId: galleryJson['photo_id'] ?? '',
            title: galleryJson['title'] ?? '',
            category: galleryJson['category']?.toLowerCase() ?? 'other',
            description: galleryJson['description'] ?? '',
            date: galleryJson['date'] != null 
                ? DateTime.parse(galleryJson['date']) 
                : DateTime.now(),
            photographer: galleryJson['photographer'] ?? '',
            location: galleryJson['location'] ?? '',
            emoji: galleryJson['emoji'] ?? '📷',
            isFavorite: galleryJson['is_favorite'] ?? false,
            imageUrls: imageUrls,
          ));
        }
      }


      
      setState(() {
        photos = fetchedItems;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  // Helper to standardise response parsing
  List<dynamic> _parseResponseList(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    } else if (data is Map && data.containsKey('data')) {
      return data['data'] as List<dynamic>;
    } else if (data is List) {
      return data as List<dynamic>;
    } else if (data is Map) {
      return [data];
    }
    return [];
  }

  DateTime _parseActivityDate(String? schedule) {
    if (schedule == null || schedule.isEmpty) return DateTime.now();
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(schedule);
    } catch (e) {
      return DateTime.now();
    }
  }

  List<GalleryPhoto> get filteredPhotos {
    var list = photos.where((p) {
      final matchesCategory =
          categoryFilter == 'all' || p.category == categoryFilter;
      final matchesYear =
          yearFilter == 'all' || p.date.year.toString() == yearFilter;
      final matchesSearch =
          searchTerm.isEmpty ||
          p.title.toLowerCase().contains(searchTerm) ||
          p.description.toLowerCase().contains(searchTerm) ||
          p.photographer.toLowerCase().contains(searchTerm);
      return matchesCategory && matchesYear && matchesSearch;
    }).toList();

    // Apply sorting
    list.sort((a, b) {
      switch (sortCriteria) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'title_asc':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'title_desc':
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case 'date_desc': // Default
        default:
          return b.date.compareTo(a.date);
      }
    });

    return list;
  }

  // --- Widget Methods for Mobile View ---

  Widget _buildStatCards(
    int totalPhotos,
    int thisMonth,
  ) {
    // Consolidated stats into a horizontal list view for mobile
    final stats = [
      {'emoji': '📸', 'number': totalPhotos, 'label': 'Total Photos'},
      {'emoji': '📅', 'number': thisMonth, 'label': 'This Month'},
    ];

    // Define the border color for the stat cards
    const statBorderColor = Color(0xff667eea);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 140, // Expanded height to prevent overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                width: 140, // Fixed width for mobile cards
                // 💥 FIX APPLIED HERE: Reduced vertical padding and added top border
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: const Border(
                    top: BorderSide(
                      color: statBorderColor, // Color applied to top border
                      width: 5.0, // Thicker border for emphasis
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  // Center alignment maintains the flow
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['emoji'] as String,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['number'].toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
                    // 💥 FIX APPLIED HERE: Ensure label text is handled well with maxLines and smaller size
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12, // Reduced font size for safety
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      // Consolidated padding for safety
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      child: Column(
        children: [
          // Search Bar (Full Width)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xffe2e2e2)),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 5),
              ],
            ),
            child: TextField(
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Color(0xff764ba2)),
                border: InputBorder.none,
                hintText: "Search title, event, or description...",
              ),
              onChanged: (v) => setState(() => searchTerm = v.toLowerCase()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selected,
    Map<String, String> items,
    void Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffe2e2e2), width: 1.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v!),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff764ba2)),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading data...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    final allItems = filteredPhotos;
    if (allItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "No items found matching the filters. Try adjusting your search!",
          ),
        ),
      );
    }

    // Segregate items
    final galleryItems = allItems.where((p) => p.category != 'events' && p.category != 'activities').toList();
    final eventItems = allItems.where((p) => p.category == 'events').toList();
    final activityItems = allItems.where((p) => p.category == 'activities').toList();

    // If a specific category filter is applied, adapt the view
    if (categoryFilter != 'all') {
      if (categoryFilter == 'events' || categoryFilter == 'activities') {
         return _buildListSection(allItems, 'Search Results');
      }
      return _buildFilteredGrid(allItems, 'Search Results');
    }

    // Simplified View: Just Galleries (Grid)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (galleryItems.isNotEmpty) ...[
          _buildFilteredGrid(galleryItems, null),
          const SizedBox(height: 24),
        ] else ...[
           const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "No photos found.",
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xff667eea),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(List<GalleryPhoto> items, String? title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _buildSectionTitle(title),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildListItem(items[index]),
        ),
      ],
    );
  }

  Widget _buildListItem(GalleryPhoto item) {
    final monthFormat = DateFormat('MMM');
    final dayFormat = DateFormat('dd');
    
    // Determine color based on category/id (pseudo-random but consistent)
    final badgeColor = item.category == 'events' 
        ? const Color(0xFFE8F5E9) // Light Green for Events
        : const Color(0xFFE3F2FD); // Light Blue for Activities
    final badgeTextColor = item.category == 'events'
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => _showImageModal(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthFormat.format(item.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                  Text(
                    dayFormat.format(item.date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.category[0].toUpperCase()}${item.category.substring(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (item.photographer.isNotEmpty) ...[
                        Text(
                          ' • ${item.photographer}', // Organizer/Instructor
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFilteredGrid(List<GalleryPhoto> items, String? title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _buildSectionTitle(title),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 columns for wider displays
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75, // Aspect ratio adjusted for 4 columns
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildGalleryCard(items[index]),
        ),
      ],
    );
  }

  // Old card method, kept for the grid view
  Widget _buildGalleryCard(GalleryPhoto photo) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    return GestureDetector(
      onTap: () => _showImageModal(photo),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Emoji Placeholder Area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: photo.imageUrls.isEmpty ? const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: photo.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          photo.imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xff667eea), Color(0xff764ba2)],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  photo.emoji,
                                  style: const TextStyle(fontSize: 50, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          photo.emoji,
                          style: const TextStyle(fontSize: 50, color: Colors.white),
                        ),
                      ),
              ),
            ),

            // Text Content Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          photo.category[0].toUpperCase() +
                              photo.category.substring(1),
                          style: const TextStyle(
                            color: Color(0xff764ba2),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatter.format(photo.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff667eea),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _showImageModal(photo),
                            child: const Text(
                              "View Details",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-screen image viewer with horizontal swipe
  void _showImageModal(GalleryPhoto photo) {
    // If it's an event or activity, show a dedicated detail dialog
    // Removed EventDetailDialog trigger since events/activities are gone


    // Otherwise show the full-screen image viewer for photos
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return _FullScreenImageViewer(photo: photo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stat calculations re-used
    final totalPhotos = photos.length;
    final thisMonth = photos
        .where(
          (p) =>
              p.date.year == DateTime.now().year &&
              p.date.month == DateTime.now().month,
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text(
          "School Gallery 📸",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff667eea),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mobile Stat Cards (Horizontal Scrollable)
            const SizedBox(height: 10), // Top buffer
            _buildStatCards(
              totalPhotos,
              thisMonth,
            ),

            const SizedBox(height: 12), // Spacing below stat cards
            // 2. Search and Filters
            _buildSearchAndFilters(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Gallery Highlights",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333333),
                ),
              ),
            ),

            // 3. Gallery Grid (4 columns)
            _buildGalleryGrid(),

            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}

// Full-screen image viewer widget
class _FullScreenImageViewer extends StatefulWidget {
  final GalleryPhoto photo;

  const _FullScreenImageViewer({required this.photo});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.photo.imageUrls.isNotEmpty;
    final imageCount = widget.photo.imageUrls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image viewer with PageView
          Center(
            child: hasImages
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: imageCount,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Center(
                        child: Image.network(
                          widget.photo.imageUrls[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.photo.emoji,
                                    style: const TextStyle(fontSize: 100),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      widget.photo.emoji,
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
          ),

          // Previous button
          if (hasImages && imageCount > 1 && _currentPage > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          // Next button
          if (hasImages && imageCount > 1 && _currentPage < imageCount - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          // Top bar with title and close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.photo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // Page indicator (if multiple images)
          if (hasImages && imageCount > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $imageCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.photo.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.photo.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.category,
                          label: widget.photo.category[0].toUpperCase() +
                              widget.photo.category.substring(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.calendar_today,
                          label: DateFormat('MMM dd, yyyy').format(widget.photo.date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.photo.location.isNotEmpty)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.location_on,
                            label: widget.photo.location,
                          ),
                        ),
                      if (widget.photo.location.isNotEmpty && widget.photo.photographer.isNotEmpty)
                        const SizedBox(width: 8),
                      if (widget.photo.photographer.isNotEmpty)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.camera_alt,
                            label: widget.photo.photographer,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          // Get current image URL
                          final currentImageUrl = widget.photo.imageUrls[_currentPage];
                          final uri = Uri.parse(currentImageUrl);
                          
                          if (await canLaunchUrl(uri)) {
                             await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                             throw Exception('Could not launch $currentImageUrl');
                          }
                        } catch (e) {
                          // Show error message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to open image: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: Text(
                        hasImages && imageCount > 1
                            ? 'Open Image ${_currentPage + 1}'
                            : 'Open Image',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Info chip widget for displaying metadata
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailDialog extends StatelessWidget {
  final GalleryPhoto photo;

  const _EventDetailDialog({required this.photo});

  @override
  Widget build(BuildContext context) {
    final isEvent = photo.category == 'events';
    final primaryColor = isEvent ? const Color(0xff667eea) : const Color(0xFF1565C0);
    final icon = isEvent ? Icons.calendar_today : Icons.sports_soccer;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(photo.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info Rows
            _buildInfoRow(Icons.location_on_outlined, 'Location', photo.location),
            if (photo.photographer.isNotEmpty)
              _buildInfoRow(
                  Icons.person_outline, 
                  isEvent ? 'Organizer' : 'Instructor', 
                  photo.photographer
              ),
            
            const SizedBox(height: 24),
            
            // Description
            const Text(
              "About",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Text(
                photo.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}