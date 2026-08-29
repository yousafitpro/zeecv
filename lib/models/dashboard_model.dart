class Dashboard {
  final int appliedCount;
  final int savedCount;
  final int myjobsCount;
  final int interviewsCount;
  final List<RecentActivity> recentActivities;

  Dashboard({
    required this.appliedCount,
    required this.savedCount,
    required this.myjobsCount,
    required this.interviewsCount,
    required this.recentActivities,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      appliedCount: json['applied_count'] ?? 0,
      savedCount: json['saved_count'] ?? 0,
      myjobsCount: json['myjobs_count'] ?? 0,
      interviewsCount: json['interviews_count'] ?? 0,
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => RecentActivity.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applied_count': appliedCount,
      'saved_count': savedCount,
      'myjobs_count': myjobsCount,
      'interviews_count': interviewsCount,
      'recent_activities': recentActivities.map((e) => e.toJson()).toList(),
    };
  }

  Dashboard copyWith({
    int? appliedCount,
    int? savedCount,
    int? myjobsCount,
    int? interviewsCount,
    List<RecentActivity>? recentActivities,
  }) {
    return Dashboard(
      appliedCount: appliedCount ?? this.appliedCount,
      savedCount: savedCount ?? this.savedCount,
      myjobsCount: myjobsCount ?? this.myjobsCount,
      interviewsCount: interviewsCount ?? this.interviewsCount,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}

class RecentActivity {
  final String title;
  final DateTime created;
  final String type; // 'apply' or 'save'

  RecentActivity({
    required this.title,
    required this.created,
    required this.type,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      title: json['title'] ?? '',
      created: DateTime.parse(json['created']),
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'created': created.toIso8601String(),
      'type': type,
    };
  }

  RecentActivity copyWith({
    String? title,
    DateTime? created,
    String? type,
  }) {
    return RecentActivity(
      title: title ?? this.title,
      created: created ?? this.created,
      type: type ?? this.type,
    );
  }

  // Helper getters
  bool get isApply => type == 'apply';
  bool get isSave => type == 'save';

  String get activityLabel {
    switch (type) {
      case 'apply':
        return 'Applied';
      case 'save':
        return 'Saved';
      default:
        return 'Unknown';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(created);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}