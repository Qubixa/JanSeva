import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Notice {
  final int id;
  final String title;
  final String message;
  final String noticeType;
  final int? wardId;
  final String? targetRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.noticeType,
    this.wardId,
    this.targetRole,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      noticeType: json['notice_type'] ?? json['noticeType'] ?? 'NOTICE',
      wardId: json['ward_id'],
      targetRole: json['target_role'],
      isActive: json['is_active'] == true || json['is_active'] == 'Y',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
    );
  }

  String get noticeIcon {
    switch (noticeType) {
      case 'ALERT':
        return '⚠️';
      case 'EVENT':
        return '🎉';
      case 'CIRCULAR':
        return '📢';
      case 'UPDATE':
        return '🔄';
      default:
        return '📰';
    }
  }

  Color get noticeColor {
    switch (noticeType) {
      case 'ALERT':
        return AppColors.error;
      case 'EVENT':
        return AppColors.success;
      case 'CIRCULAR':
        return AppColors.info;
      case 'UPDATE':
        return AppColors.warning2;
      default:
        return AppColors.secondary;
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}