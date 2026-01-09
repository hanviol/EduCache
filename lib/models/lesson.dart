enum LessonType { video, text, pdf, audio, reading, quiz }

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final LessonType type; // video | pdf
  final String remoteUrl;
  final String? localPath;
  final String? subtitleUrl;
  final int durationSeconds;
  final bool isDownloaded;
  final double progress; // 0.0 to 1.0

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.remoteUrl,
    this.localPath,
    this.subtitleUrl,
    this.durationSeconds = 0,
    this.isDownloaded = false,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'type': type.name,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'subtitleUrl': subtitleUrl,
      'durationSeconds': durationSeconds,
      'isDownloaded': isDownloaded,
      'progress': progress,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      title: map['title'] as String,
      type: LessonType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => LessonType.video,
      ),
      remoteUrl: map['remoteUrl'] as String? ?? '',
      localPath: map['localPath'] as String?,
      subtitleUrl: map['subtitleUrl'] as String?,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      isDownloaded: map['isDownloaded'] as bool? ?? false,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Lesson copyWith({
    String? id,
    String? courseId,
    String? title,
    LessonType? type,
    String? remoteUrl,
    String? localPath,
    bool? isDownloaded,
    double? progress,
  }) {
    return Lesson(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      type: type ?? this.type,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      progress: progress ?? this.progress,
    );
  }
}
