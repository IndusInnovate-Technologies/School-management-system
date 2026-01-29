"""
Admin configuration for student_parent app
"""
from django.contrib import admin
from .models import Parent, Notification, Fee, Communication, ChatMessage


@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    list_display = ['user', 'phone', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'user__email', 'phone']
    filter_horizontal = ['students']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['recipient', 'title', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['title', 'message', 'recipient__username']


@admin.register(Fee)
class FeeAdmin(admin.ModelAdmin):
    list_display = ['student', 'amount', 'due_date', 'status', 'payment_date', 'created_at']
    list_filter = ['status', 'due_date', 'created_at']
    search_fields = ['student__user__username', 'description']


@admin.register(Communication)
class CommunicationAdmin(admin.ModelAdmin):
    list_display = ['sender', 'recipient', 'subject', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at']
    search_fields = ['subject', 'message', 'sender__username', 'recipient__username']


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'recipient', 'message_type', 'is_read', 'is_deleted', 'created_at']
    list_filter = ['message_type', 'is_read', 'is_deleted', 'created_at']
    search_fields = ['message_text', 'attachment_name', 'sender__username', 'recipient__username']
    readonly_fields = ['message_id', 'created_at', 'updated_at', 'read_at', 'deleted_at']
    date_hierarchy = 'created_at'

