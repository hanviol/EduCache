class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int coursesCompleted;
  final int hoursLearned;
  final int streakDays;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.coursesCompleted,
    required this.hoursLearned,
    required this.streakDays,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? coursesCompleted,
    int? hoursLearned,
    int? streakDays,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coursesCompleted: coursesCompleted ?? this.coursesCompleted,
      hoursLearned: hoursLearned ?? this.hoursLearned,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}
