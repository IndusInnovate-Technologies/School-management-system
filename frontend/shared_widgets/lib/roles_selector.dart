import 'package:flutter/material.dart';
import 'package:core/utils/constants.dart';

/// Common UI component - Roles Selector
class RolesSelector extends StatefulWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;
  final List<String>? availableRoles;
  final bool isHorizontal;
  final double? spacing;

  const RolesSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.availableRoles,
    this.isHorizontal = true,
    this.spacing,
  });

  @override
  State<RolesSelector> createState() => _RolesSelectorState();
}

class _RolesSelectorState extends State<RolesSelector> {
  late String _selectedRole;

  final Map<String, Map<String, dynamic>> _roleData = {
    AppConstants.roleAdmin: {
      'title': 'Admin',
      'subtitle': 'Full access',
      'icon': Icons.business_center_rounded,
    },
    AppConstants.roleManagement: {
      'title': 'Management',
      'subtitle': 'Control access',
      'icon': Icons.apartment_rounded,
    },
    AppConstants.roleTeacher: {
      'title': 'Teacher',
      'subtitle': 'Academic access',
      'icon': Icons.school,
    },
    AppConstants.roleParent: {
      'title': 'Parent',
      'subtitle': 'Student access',
      'icon': Icons.family_restroom,
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  void didUpdateWidget(RolesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRole != widget.selectedRole) {
      _selectedRole = widget.selectedRole;
    }
  }

  List<String> get _roles {
    return widget.availableRoles ??
        [
          AppConstants.roleAdmin,
          AppConstants.roleManagement,
          AppConstants.roleTeacher,
          AppConstants.roleParent,
        ];
  }

  Widget _buildRoleTile(String role) {
    final roleInfo = _roleData[role] ?? {
      'title': role.toUpperCase(),
      'subtitle': '',
      'icon': Icons.person,
    };
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
        widget.onRoleChanged(role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(AppConstants.primaryColorValue),
                    Color(AppConstants.secondaryColorValue),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(AppConstants.primaryColorValue)
                : const Color(0xFFDEE2E6),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(AppConstants.primaryColorValue).withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    roleInfo['icon'] as IconData,
                    size: 26,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    roleInfo['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  if ((roleInfo['subtitle'] as String?) != null &&
                      (roleInfo['subtitle'] as String?)!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      roleInfo['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHorizontal) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: widget.spacing ?? 18,
        mainAxisSpacing: widget.spacing ?? 18,
        childAspectRatio: 1.6,
        children: _roles.map((role) => _buildRoleTile(role)).toList(),
      );
    } else {
      return Column(
        children: _roles
            .map((role) => Padding(
                  padding: EdgeInsets.only(
                    bottom: role == _roles.last ? 0 : (widget.spacing ?? 12),
                  ),
                  child: _buildRoleTile(role),
                ))
            .toList(),
      );
    }
  }
}

