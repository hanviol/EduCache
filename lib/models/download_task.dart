enum DownloadStatus { queued, downloading, completed, failed }

class DownloadTask {
  final String id;
  final String courseId;
  final String lessonId;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0

  DownloadTask({
    required this.id,
    required this.courseId,
    required this.lessonId,
    required this.status,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'lessonId': lessonId,
      'status': status.name,
      'progress': progress,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      lessonId: map['lessonId'] as String? ?? '',
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DownloadStatus.queued,
      ),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DownloadTask copyWith({
    String? id,
    String? courseId,
    String? lessonId,
    DownloadStatus? status,
    double? progress,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
