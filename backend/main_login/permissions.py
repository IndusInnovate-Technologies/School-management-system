"""
Custom permissions for main_login app
"""
from rest_framework import permissions


class IsSuperAdmin(permissions.BasePermission):
    """Permission check for Super Admin role"""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role and
            request.user.role.name == 'super_admin'
        )


class IsManagementAdmin(permissions.BasePermission):
    """Permission check for Management Admin role"""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role and
            request.user.role.name == 'management_admin'
        )


class IsTeacher(permissions.BasePermission):
    """Permission check for Teacher role"""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role and
            request.user.role.name == 'teacher'
        )


class IsStudentParent(permissions.BasePermission):
    """Permission check for Student/Parent role"""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role and
            request.user.role.name == 'student_parent'
        )


class IsSuperAdminOrManagementAdmin(permissions.BasePermission):
    """Permission check for Super Admin or Management Admin"""
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated and request.user.role):
            return False
        return request.user.role.name in ['super_admin', 'management_admin']


class IsAdminOrTeacher(permissions.BasePermission):
    """Permission check for Admin or Teacher"""
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated and request.user.role):
            return False
        return request.user.role.name in ['super_admin', 'management_admin', 'teacher']


class IsFinancial(permissions.BasePermission):
    """Permission check for Financial role"""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role and
            request.user.role.name == 'financial'
        )


class IsReadOnly(permissions.BasePermission):
    """
    The request is a read-only request.
    """
    def has_permission(self, request, view):
        return request.method in permissions.SAFE_METHODS

