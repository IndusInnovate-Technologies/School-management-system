import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/add_staff_dialog.dart';
import 'widgets/edit_staff_dialog.dart';
import 'financial_dashboard.dart';

class FinancialProfilesPage extends StatefulWidget {
  final VoidCallback? onBackToFees;
  
  const FinancialProfilesPage({Key? key, this.onBackToFees}) : super(key: key);

  @override
  State<FinancialProfilesPage> createState() => _FinancialProfilesPageState();
}

class _FinancialProfilesPageState extends State<FinancialProfilesPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _financialUsers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFinancialUsers();
  }

  Future<void> _loadFinancialUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(Endpoints.financialUsers);
      
      if (response.success && response.data != null) {
        final data = response.data;
        List<Map<String, dynamic>> users = [];
        
        if (data is List) {
          users = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['results'] != null) {
          users = (data['results'] as List).cast<Map<String, dynamic>>();
        }
        
        setState(() {
          _financialUsers = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load financial users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleBackButton(BuildContext context) {
    if (widget.onBackToFees != null) {
      widget.onBackToFees!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Staff'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackButton(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialUsers,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffDialog,
        backgroundColor: const Color(0xFF667EEA),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStaffDialog(onSuccess: _loadFinancialUsers),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFinancialUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_financialUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Financial Staff Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Click the + button to add financial staff',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFinancialUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _financialUsers.length,
        itemBuilder: (context, index) {
          final user = _financialUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? 'Unknown';
    final name = (firstName.isNotEmpty || lastName.isNotEmpty) 
        ? '$firstName $lastName'.trim() 
        : username;
    
    final email = user['email'] ?? 'No email';
    final phone = user['mobile'] ?? user['phone'] ?? 'No phone';
    final isActive = user['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF667EEA),
          radius: 28,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'F',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Color(0xFF667EEA)),
              tooltip: 'View Details',
              onPressed: () => _showViewDialog(user),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: 'Edit',
              onPressed: () => _showEditDialog(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _showDeleteConfirmation(user),
            ),
          ],
        ),
        onTap: null,
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final phone = user['mobile'] ?? '';
    final isActive = user['is_active'] ?? true;
    final userId = user['user_id'] ?? '';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Username', username),
              _buildDetailRow('Email', email),
              _buildDetailRow('Phone', phone.isEmpty ? 'Not provided' : phone),
              _buildDetailRow('User ID', userId),
              _buildDetailRow('Status', isActive ? 'Active' : 'Inactive'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => EditStaffDialog(
        user: user,
        onSuccess: _loadFinancialUsers,
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    final name = (user['first_name'] ?? '') + ' ' + (user['last_name'] ?? '');
    final displayName = name.trim().isEmpty ? user['username'] ?? 'this user' : name.trim();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Are you sure you want to delete $displayName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser(user);
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = user['user_id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID not found')),
      );
      return;
    }

    try {
      final response = await _apiService.delete('${Endpoints.financialUsers}$userId/');
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member deleted successfully')),
        );
        _loadFinancialUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to delete staff member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
