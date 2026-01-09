import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/lesson.dart';

/// Service to interact strictly with Internet Archive APIs.
class InternetArchiveService {
  static const String _searchUrl = 'https://archive.org/advancedsearch.php';
  static const String _metadataUrl = 'https://archive.org/metadata';

  final http.Client _client = http.Client();

  /// Search for educational courses using advancedsearch.php
  Future<List<Course>> searchCourses() async {
    // Strict educational query - searching specifically for collections known to have course materials
    // Filter for items larger than 10MB to ensure multiple lessons/substantial content
    const query =
        '(collection:mit_ocw OR collection:khanacademy OR collection:education OR collection:scitech) AND (mediatype:movies OR mediatype:texts OR mediatype:audio) AND item_size:[10000000 TO null]';
    final fields = ['identifier', 'title', 'description', 'subject', 'creator'];

    final uri = Uri.parse(
        '$_searchUrl?q=$query&rows=40&output=json&${fields.map((f) => "fl[]=$f").join("&")}');

    print('IA_LOG: Initializing search for courses: $uri');

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('IA_LOG: Error search failed with status ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final rawDocs = data['response']?['docs'] as List? ?? [];

      if (rawDocs.isEmpty) {
        print('IA_LOG: ERROR - Zero courses found.');
        return [];
      }

      final List<Course> courses = [];
      for (var doc in rawDocs) {
        final identifier = doc['identifier'];
        if (identifier == null) continue;

        final title = doc['title'] ?? identifier;
        final description = _truncateDescription(doc['description']);

        final subject = _mapToSubject(doc['subject'], title, description);
        final category = _mapToCategory(subject);

        courses.add(Course(
          id: identifier,
          title: doc['title'] ?? identifier,
          description: _truncateDescription(doc['description']),
          subjectTag: subject, // Precise subject like "Calculus"
          category: category, // High level category like "Mathematics"
          thumbnailUrl: 'https://archive.org/services/img/$identifier',
          totalLessons: 0, // Will be updated when fetching metadata
          downloadedLessons: 0,
          progress: 0.0,
          status: 'available',
        ));
      }

      print('IA_LOG: Parsed ${courses.length} courses successfully');
      return courses;
    } on TimeoutException {
      print('IA_LOG: searchCourses timed out');
      return [];
    } catch (e) {
      print('IA_LOG: Exception in searchCourses: $e');
      return [];
    }
  }

  /// Fetch lessons for a specific identifier using metadata API
  Future<List<Lesson>> fetchCourseLessons(String identifier,
      {String quality = 'medium'}) async {
    final uri = Uri.parse('$_metadataUrl/$identifier');
    print('IA_LOG: Fetching metadata for course ID: $identifier');

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        print(
            'IA_LOG: Error metadata fetch failed with ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final List files = data['files'] ?? [];

      // Group files by base name to find subtitles and quality variants
      final Map<String, Map<String, dynamic>> lessonGroups = {};

      for (var file in files) {
        final String? fileName = file['name'];
        if (fileName == null) continue;

        // Skip system files
        if (fileName.startsWith('__ia_thumb') ||
            fileName.endsWith('_meta.xml') ||
            fileName.endsWith('_files.xml')) {
          continue;
        }

        // Identify file type
        final String lower = fileName.toLowerCase();

        // Grouping key: reduce "lecture_01_512kb.mp4" to "lecture_01"
        // and "lecture_01.srt" to "lecture_01"
        String baseName = fileName;
        // Remove extension
        if (baseName.contains('.')) {
          baseName = baseName.substring(0, baseName.lastIndexOf('.'));
        }
        // Remove quality suffix if present (common in IA)
        baseName = baseName.replaceAll('_512kb', '');

        if (lessonGroups[baseName] == null) {
          lessonGroups[baseName] = {
            'videos': <Map<String, dynamic>>[],
            'pdfs': <Map<String, dynamic>>[],
            'subtitles': <Map<String, dynamic>>[],
          };
        }

        if (lower.endsWith('.mp4')) {
          lessonGroups[baseName]!['videos'].add(file);
        } else if (lower.endsWith('.pdf')) {
          lessonGroups[baseName]!['pdfs'].add(file);
        } else if (lower.endsWith('.srt') || lower.endsWith('.vtt')) {
          lessonGroups[baseName]!['subtitles'].add(file);
        }
      }

      final List<Lesson> lessons = [];

      lessonGroups.forEach((baseName, group) {
        // Process Videos
        final videos = group['videos'] as List<Map<String, dynamic>>;
        if (videos.isNotEmpty) {
          // Quality selection
          Map<String, dynamic> selectedVideo;

          if (quality == 'low') {
            // Prefer _512kb
            selectedVideo = videos.firstWhere(
              (v) => (v['name'] as String).contains('_512kb'),
              orElse: () => videos.first, // Fallback to any
            );
          } else {
            // Prefer standard (high/med) - usually without _512kb
            selectedVideo = videos.firstWhere(
              (v) => !(v['name'] as String).contains('_512kb'),
              orElse: () => videos.first,
            );
          }

          // Duration
          int duration = 0;
          if (selectedVideo['length'] != null) {
            final lengthStr = selectedVideo['length'].toString();
            // Format can be "123.45" (seconds) or "MM:SS"
            if (lengthStr.contains(':')) {
              // Parse MM:SS or HH:MM:SS
              final parts = lengthStr.split(':').map(int.parse).toList();
              if (parts.length == 3) {
                duration = parts[0] * 3600 + parts[1] * 60 + parts[2];
              } else if (parts.length == 2) {
                duration = parts[0] * 60 + parts[1];
              }
            } else {
              duration = double.tryParse(lengthStr)?.toInt() ?? 0;
            }
          }

          // Subtitles
          final subtitles = group['subtitles'] as List<Map<String, dynamic>>;
          String? subtitleUrl;
          if (subtitles.isNotEmpty) {
            final subFile = subtitles.first['name'];
            subtitleUrl = 'https://archive.org/download/$identifier/$subFile';
          }

          final fileName = selectedVideo['name'] as String;
          lessons.add(Lesson(
            id: fileName,
            courseId: identifier,
            title: _cleanFileName(fileName),
            type: LessonType.video,
            remoteUrl: 'https://archive.org/download/$identifier/$fileName',
            subtitleUrl: subtitleUrl,
            durationSeconds: duration,
            isDownloaded: false,
            progress: 0.0,
          ));
        }

        // Process PDFs
        final pdfs = group['pdfs'] as List<Map<String, dynamic>>;
        for (var pdf in pdfs) {
          final fileName = pdf['name'] as String;
          lessons.add(Lesson(
            id: fileName,
            courseId: identifier,
            title: _cleanFileName(fileName),
            type: LessonType.pdf,
            remoteUrl: 'https://archive.org/download/$identifier/$fileName',
            isDownloaded: false,
            progress: 0.0,
          ));
        }
      });

      // Sort by title to ensure order
      lessons.sort((a, b) => a.title.compareTo(b.title));

      print('IA_LOG: Parsed ${lessons.length} lessons for $identifier');
      return lessons;
    } on TimeoutException {
      print('IA_LOG: fetchCourseLessons timed out for $identifier');
      return [];
    } catch (e) {
      print('IA_LOG: Exception in fetchCourseLessons: $e');
      return [];
    }
  }

  String _cleanFileName(String name) {
    return name
        .replaceAll('_', ' ')
        .replaceFirst(RegExp(r'\.(mp4|pdf)$', caseSensitive: false), '')
        .trim();
  }

  String _mapToCategory(String subjectTag) {
    final lower = subjectTag.toLowerCase();

    // Computer Science & Tech
    if (lower.contains('computer') ||
        lower.contains('software') ||
        lower.contains('algorithms') ||
        lower.contains('programming') ||
        lower.contains('technology') ||
        lower.contains('data') ||
        lower.contains('statistics')) {
      return 'Computer Science';
    }

    // Mathematics
    if (lower.contains('math') ||
        lower.contains('calculus') ||
        lower.contains('algebra') ||
        lower.contains('geometry')) {
      return 'Mathematics';
    }

    // Sciences
    if (lower.contains('physics') ||
        lower.contains('biology') ||
        lower.contains('chemistry') ||
        lower.contains('science') ||
        lower.contains('astronomy') ||
        lower.contains('environment') ||
        lower.contains('earth')) {
      return 'Natural Sciences';
    }

    // Engineering
    if (lower.contains('engineering') ||
        lower.contains('mechanics') ||
        lower.contains('robotics')) {
      return 'Engineering';
    }

    // Business
    if (lower.contains('business') ||
        lower.contains('economics') ||
        lower.contains('finance') ||
        lower.contains('management') ||
        lower.contains('marketing')) {
      return 'Business & Economics';
    }

    // Humanities
    if (lower.contains('history') ||
        lower.contains('philosophy') ||
        lower.contains('art') ||
        lower.contains('film') ||
        lower.contains('design') ||
        lower.contains('literature') ||
        lower.contains('language') ||
        lower.contains('music') ||
        lower.contains('psychology') ||
        lower.contains('sociology') ||
        lower.contains('anthropology') ||
        lower.contains('political') ||
        lower.contains('law')) {
      return 'Humanities';
    }

    return 'Personal Development';
  }

  String _mapToSubject(dynamic subject, String title, String description) {
    if (subject == null) return 'General';
    List<String> subjects = [];
    if (subject is List) {
      subjects = subject.map((e) => e.toString()).toList();
    } else {
      subjects = [subject.toString()];
    }

    // Prioritized list of known educational domains
    // Prioritized list of known educational domains with broader keyword matching
    final prioritizedsubjects = {
      // Computer Science & Tech
      'computer science': 'Computer Science',
      'programming': 'Computer Science',
      'coding': 'Computer Science',
      'software': 'Computer Science',
      'algorithm': 'Computer Science',
      'python': 'Computer Science',
      'java': 'Computer Science',
      'c++': 'Computer Science',
      'web develop': 'Computer Science',
      'machine learning': 'Computer Science',
      'artificial intelligence': 'Computer Science',
      'ai': 'Computer Science',
      'database': 'Computer Science',
      'cybersecurity': 'Computer Science',
      'network': 'Computer Science',

      // Mathematics
      'math': 'Mathematics',
      'algebra': 'Mathematics',
      'calculus': 'Mathematics',
      'geometry': 'Mathematics',
      'statistics': 'Mathematics',
      'probability': 'Mathematics',
      'trigonometry': 'Mathematics',
      'arithmetic': 'Mathematics',
      'linear algebra': 'Mathematics',
      'differential equations': 'Mathematics',

      // Natural Sciences
      'physics': 'Physics',
      'mechanics': 'Physics',
      'thermodynamics': 'Physics',
      'quantum': 'Physics',
      'biology': 'Biology',
      'genetics': 'Biology',
      'anatomy': 'Biology',
      'chemistry': 'Chemistry',
      'organic chemistry': 'Chemistry',
      'astronomy': 'Astronomy',
      'cosmology': 'Astronomy',
      'geology': 'Earth Science',
      'environment': 'Environmental Science',

      // Engineering
      'engineering': 'Engineering',
      'electronics': 'Engineering',
      'circuits': 'Engineering',
      'robotics': 'Engineering',
      'mechanical': 'Engineering',

      // Business & Economics
      'economics': 'Economics',
      'microeconomics': 'Economics',
      'macroeconomics': 'Economics',
      'finance': 'Finance',
      'accounting': 'Business',
      'marketing': 'Business',
      'management': 'Business',
      'business': 'Business',
      'entrepreneurship': 'Business',
      'strategy': 'Business',

      // Humanities & Social Sciences
      'history': 'History',
      'civilization': 'History',
      'philosophy': 'Philosophy',
      'psychology': 'Psychology',
      'sociology': 'Sociology',
      'anthropology': 'Anthropology',
      'political': 'Political Science',
      'government': 'Political Science',
      'law': 'Law',
      'ethics': 'Philosophy',

      // Arts & Literature
      'art': 'Arts',
      'music': 'Arts',
      'theater': 'Arts',
      'design': 'Design',
      'film': 'Film',
      'literature': 'Literature',
      'writing': 'Literature',
      'english': 'Literature',
      'language': 'Languages',
      'linguistics': 'Languages',
    };

    // List of subjects to ignore (authors, generic terms)
    final ignoredSubjects = [
      'salman khan',
      'khan academy',
      'video',
      'education',
      'instructional',
      'lecture',
      'course',
      'mit',
      'opencourseware',
      'general',
      'academic',
    ];

    // Helper to check text against keywords
    String? checkKeywords(String text) {
      final lower = text.toLowerCase();
      for (var entry in prioritizedsubjects.entries) {
        if (lower.contains(entry.key)) {
          return entry.value;
        }
      }
      return null;
    }

    // 1. Scan subjects for prioritized keywords
    for (var s in subjects) {
      final match = checkKeywords(s);
      if (match != null) return match;
    }

    // 2. Scan Title for prioritized keywords
    final titleMatch = checkKeywords(title);
    if (titleMatch != null) return titleMatch;

    // 3. Scan Description for prioritized keywords
    final descMatch = checkKeywords(description);
    if (descMatch != null) return descMatch;

    // 4. Fallback: filter out ignored subjects from properties
    for (var s in subjects) {
      final candidate = s.split(RegExp(r'[,;]')).first.trim();
      final lower = candidate.toLowerCase();

      var isIgnored = false;
      for (var ignored in ignoredSubjects) {
        if (lower.contains(ignored)) {
          isIgnored = true;
          break;
        }
      }

      if (!isIgnored && candidate.isNotEmpty) {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }

    // 5. Last resort
    return 'General Education';
  }

  String _truncateDescription(dynamic desc) {
    if (desc == null) return 'No description available.';

    String s =
        desc.toString().replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();

    if (s.length > 200) {
      return '${s.substring(0, 197)}...';
    }
    return s;
  }
}
