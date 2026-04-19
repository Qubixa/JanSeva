// lib/core/models/complaint_model.dart

class ComplaintCategory {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? icon;
  final String? department;
  final bool isActive;

  const ComplaintCategory({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.icon,
    this.department,
    this.isActive = true,
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ComplaintCategory(
        id: 0,
        code: '',
        name: '',
        isActive: true,
      );
    }
    return ComplaintCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      department: json['department'] as String?,
      isActive: (json['is_active'] as String?) == 'Y' || json['is_active'] == true,
    );
  }

  String get iconName => icon ?? 'report_problem';
}

// ---------------------------------------------------------------------------

class UserBrief {
  final int id;
  final String name;
  final String mobile;

  const UserBrief({
    required this.id,
    required this.name,
    required this.mobile,
  });

  factory UserBrief.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserBrief(id: 0, name: '', mobile: '');
    }
    return UserBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------

class WardBrief {
  final int id;
  final String name;

  const WardBrief({
    required this.id,
    required this.name,
  });

  factory WardBrief.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WardBrief(id: 0, name: '');
    }
    return WardBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------

class OfficerBrief {
  final int id;
  final String name;

  const OfficerBrief({
    required this.id,
    required this.name,
  });

  factory OfficerBrief.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const OfficerBrief(id: 0, name: '');
    }
    return OfficerBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------

class ComplaintMedia {
  final int id;
  final String filePath;
  final String fileType;
  final String? fileName;
  final DateTime uploadedAt;

  const ComplaintMedia({
    required this.id,
    required this.filePath,
    required this.fileType,
    this.fileName,
    required this.uploadedAt,
  });

  factory ComplaintMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ComplaintMedia(
        id: 0,
        filePath: '',
        fileType: '',
        uploadedAt: DateTime.now(),
      );
    }
    return ComplaintMedia(
      id: (json['id'] as num?)?.toInt() ?? 0,
      filePath: json['file_path'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileName: json['file_name'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isImage => fileType == 'IMAGE' || fileType == 'PROOF_IMAGE';
}

// ---------------------------------------------------------------------------

class ComplaintLog {
  final int id;
  final String action;
  final String? oldStatus;
  final String? newStatus;
  final String? remarks;
  final String? actionByName;
  final DateTime createdAt;

  const ComplaintLog({
    required this.id,
    required this.action,
    this.oldStatus,
    this.newStatus,
    this.remarks,
    this.actionByName,
    required this.createdAt,
  });

  factory ComplaintLog.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ComplaintLog(
        id: 0,
        action: '',
        createdAt: DateTime.now(),
      );
    }
    return ComplaintLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      action: json['action'] as String? ?? '',
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      remarks: json['remarks'] as String?,
      actionByName: json['action_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get actionDisplay {
    const labels = {
      'CREATED': 'Complaint Filed',
      'ASSIGNED': 'Assigned to Officer',
      'AUTO_ASSIGNED': 'Auto-Assigned to Officer',
      'MANUALLY_ASSIGNED': 'Manually Assigned',
      'STATUS_UPDATED': 'Status Updated',
      'RESOLVED': 'Resolved',
      'REJECTED': 'Rejected',
      'FEEDBACK_SUBMITTED': 'Feedback Submitted',
    };
    return labels[action] ??
        action
            .split('_')
            .map((w) => w.isEmpty
                ? ''
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
  }
}

// ---------------------------------------------------------------------------

class ComplaintStats {
  final int total;
  final int pending;
  final int assigned;
  final int inProgress;
  final int resolved;
  final int rejected;
  final int closed;

  const ComplaintStats({
    this.total = 0,
    this.pending = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.resolved = 0,
    this.rejected = 0,
    this.closed = 0,
  });

  factory ComplaintStats.fromComplaints(List<Complaint> list) {
    return ComplaintStats(
      total: list.length,
      pending: list.where((c) => c.status == 'PENDING').length,
      assigned: list.where((c) => c.status == 'ASSIGNED').length,
      inProgress: list.where((c) => c.status == 'IN_PROGRESS').length,
      resolved: list.where((c) => c.status == 'RESOLVED').length,
      rejected: list.where((c) => c.status == 'REJECTED').length,
      closed: list.where((c) => c.status == 'CLOSED').length,
    );
  }

  factory ComplaintStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ComplaintStats();
    return ComplaintStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      closed: (json['closed'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------

class Complaint {
  final int id;
  final String complaintNumber;
  final String category;
  final String title;
  final String description;
  final String address;
  final String? latitude;
  final String? longitude;
  final String status;
  final String priority;
  final String? resolutionRemarks;
  final String? feedback;
  final int? rating;
  final int userId;
  final UserBrief? user;
  final int wardId;
  final WardBrief? ward;
  final int? assignedOfficerId;
  final OfficerBrief? assignedOfficer;
  final String? userName;
  final String? userMobile;
  final String? wardName;
  final String? assignedOfficerName;
  final ComplaintCategory? categoryInfo;
  final List<ComplaintMedia> media;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const Complaint({
    required this.id,
    required this.complaintNumber,
    required this.category,
    required this.title,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    required this.status,
    required this.priority,
    this.resolutionRemarks,
    this.feedback,
    this.rating,
    required this.userId,
    this.user,
    required this.wardId,
    this.ward,
    this.assignedOfficerId,
    this.assignedOfficer,
    this.userName,
    this.userMobile,
    this.wardName,
    this.assignedOfficerName,
    this.categoryInfo,
    required this.media,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  String? get resolvedNotes => resolutionRemarks;
  
  String get displayUserName => user?.name ?? userName ?? 'Unknown';
  String get displayUserMobile => user?.mobile ?? userMobile ?? '';
  String get displayWardName => ward?.name ?? wardName ?? 'N/A';
  String get displayOfficerName => assignedOfficer?.name ?? assignedOfficerName ?? 'Unassigned';

  factory Complaint.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Complaint(
        id: 0,
        complaintNumber: '',
        category: '',
        title: '',
        description: '',
        address: '',
        status: 'PENDING',
        priority: 'MEDIUM',
        userId: 0,
        wardId: 0,
        media: const [],
        createdAt: DateTime.now(),
      );
    }
    
    return Complaint(
      id: (json['id'] as num?)?.toInt() ?? 0,
      complaintNumber: json['complaint_number'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      priority: json['priority'] as String? ?? 'MEDIUM',
      resolutionRemarks: json['resolution_remarks'] as String?,
      feedback: json['feedback'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      user: UserBrief.fromJson(json['user'] as Map<String, dynamic>?),
      wardId: (json['ward_id'] as num?)?.toInt() ?? 0,
      ward: WardBrief.fromJson(json['ward'] as Map<String, dynamic>?),
      assignedOfficerId: (json['assigned_officer_id'] as num?)?.toInt(),
      assignedOfficer: OfficerBrief.fromJson(json['assigned_officer'] as Map<String, dynamic>?),
      userName: json['user_name'] as String?,
      userMobile: json['user_mobile'] as String?,
      wardName: json['ward_name'] as String?,
      assignedOfficerName: json['assigned_officer_name'] as String?,
      categoryInfo: ComplaintCategory.fromJson(json['category_info'] as Map<String, dynamic>?),
      media: ((json['media'] as List<dynamic>?) ?? [])
          .map((m) => ComplaintMedia.fromJson(m as Map<String, dynamic>?))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
    );
  }

  String getStatusDisplay() {
    const m = {
      'PENDING': 'Pending',
      'ASSIGNED': 'Assigned',
      'IN_PROGRESS': 'In Progress',
      'RESOLVED': 'Resolved',
      'REJECTED': 'Rejected',
      'CLOSED': 'Closed',
    };
    return m[status.toUpperCase()] ?? status;
  }

  String getPriorityDisplay() {
    const m = {
      'LOW': 'Low',
      'MEDIUM': 'Medium',
      'HIGH': 'High',
      'URGENT': 'Urgent',
    };
    return m[priority.toUpperCase()] ?? priority;
  }

  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';
  bool get isPending => status == 'PENDING';
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;
  bool get canSubmitFeedback => isResolved && !hasFeedback;
}