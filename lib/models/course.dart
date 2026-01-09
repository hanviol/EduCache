enum CourseSource { mitOcw, openLearn, youtube, internetArchive, unknown }

class Course {
  final String id;
  final String title;
  final String description;
  final String subjectTag;
  final String category;
  final String thumbnailUrl;
  final int totalLessons;
  final int downloadedLessons;
  final double progress;
  final DateTime? lastAccessedAt;
  final String status; // 'downloaded', 'downloading', 'available'

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectTag,
    required this.category,
    required this.thumbnailUrl,
    required this.totalLessons,
    required this.downloadedLessons,
    required this.progress,
    this.lastAccessedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectTag': subjectTag,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'totalLessons': totalLessons,
      'downloadedLessons': downloadedLessons,
      'progress': progress,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'status': status,
    };
  }

  factory Course.fromMap(Map<dynamic, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      subjectTag: map['subjectTag'] as String? ?? 'General',
      category: map['category'] as String? ??
          'General Education', // Fallback/Migration
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      totalLessons:
          map['totalLessons'] as int? ?? map['lessonCount'] as int? ?? 0,
      downloadedLessons: map['downloadedLessons'] as int? ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.parse(map['lastAccessedAt'] as String)
          : null,
      status: map['status'] as String? ?? 'available',
    );
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectTag,
    String? category,
    String? thumbnailUrl,
    int? totalLessons,
    int? downloadedLessons,
    double? progress,
    DateTime? lastAccessedAt,
    String? status,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectTag: subjectTag ?? this.subjectTag,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalLessons: totalLessons ?? this.totalLessons,
      downloadedLessons: downloadedLessons ?? this.downloadedLessons,
      progress: progress ?? this.progress,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
    );
  }
}
