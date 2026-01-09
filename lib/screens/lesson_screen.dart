import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    hide ProgressBar;
import '../widgets/progress_bar.dart';
import '../models/lesson.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Lesson? _lesson;
  String? _courseId;
  List<Lesson> _allLessons = [];
  int _currentLessonIndex = 0;
  bool _isLoading = true;

  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLesson();
    });
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is! Map) {
      setState(() => _isLoading = false);
      return;
    }

    final String? courseId = args['courseId'];
    final String? lessonId = args['lessonId'];

    if (courseId == null || lessonId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repository = ref.read(courseRepositoryProvider);
    final lessons = await repository.getLessons(courseId);
    final lessonIndex = lessons.indexWhere((l) => l.id == lessonId);

    if (lessonIndex != -1) {
      final lesson = lessons[lessonIndex];
      setState(() {
        _lesson = lesson;
        _courseId = courseId;
        _allLessons = lessons;
        _currentLessonIndex = lessonIndex;
        _isLoading = false;
      });

      // Extract YouTube ID if applicable
      final ytId = YoutubePlayer.convertUrlToId(lesson.remoteUrl);
      if (ytId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: ytId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
      } else if (lesson.type == LessonType.video ||
          lesson.type == LessonType.audio) {
        // Initialize Internal Player
        _initializeVideoPlayer(lesson);
      }

      // Update last accessed time for Continue Learning
      ref.read(courseRepositoryProvider).updateLastAccessed(courseId);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideoPlayer(Lesson lesson) async {
    // Dispose previous controllers if any (in case of navigation within same screen state)
    await _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;

    final isDownloaded =
        lesson.localPath != null && File(lesson.localPath!).existsSync();
    final url = isDownloaded ? lesson.localPath! : lesson.remoteUrl;

    if (isDownloaded) {
      _videoController = VideoPlayerController.file(File(url));
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      await _videoController!.initialize();
      // Ensure sound is ON by default
      await _videoController!.setVolume(1.0);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: lesson.type == LessonType.audio
            ? 16 / 4 // Wider/shorter for audio
            : _videoController!.value.aspectRatio,
        // Add Subtitle Support
        subtitle: lesson.subtitleUrl != null
            ? Subtitles([
                Subtitle(
                  index: 0,
                  start: Duration.zero,
                  end: _videoController!.value.duration,
                  text: 'Subtitles available via CC button',
                ),
              ])
            : null,
        subtitleBuilder: (context, dynamic subtitle) {
          return Container(
            padding: const EdgeInsets.all(10),
            child: Text(
              subtitle.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('IA_LOG: Player Initialization Error: $e');
    }
  }

  Future<void> _markLessonComplete() async {
    if (_lesson == null || _courseId == null) return;

    final repository = ref.read(courseRepositoryProvider);
    await repository.updateLessonCompletion(_courseId!, _lesson!.id, true);

    // Fetch updated lessons to get the new status/progress
    final lessons = await repository.getLessons(_courseId!);
    final updatedLessonIndex = lessons.indexWhere((l) => l.id == _lesson!.id);

    if (updatedLessonIndex != -1) {
      setState(() {
        _lesson = lessons[updatedLessonIndex];
        _allLessons = lessons;
      });
    }

    // Update last activity for streak
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(profileServiceProvider).updateLastActivity(user.id);
      ref.invalidate(userProfileProvider);
    }

    ref.invalidate(courseProvider(_courseId!));
    ref.invalidate(lessonsProvider(_courseId!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson completed!')),
      );
    }
  }

  Future<void> _openInBrowser() async {
    if (_lesson?.remoteUrl != null) {
      final uri = Uri.parse(_lesson!.remoteUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildContentWidget() {
    if (_lesson == null) return const SizedBox();

    final ytId = YoutubePlayer.convertUrlToId(_lesson!.remoteUrl);
    if (ytId != null && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        onReady: () {},
      );
    }

    // Handle Internal Video/Audio Player
    if (_lesson!.type == LessonType.video ||
        _lesson!.type == LessonType.audio) {
      if (_chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized) {
        return Container(
          height: _lesson!.type == LessonType.audio ? 100 : 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Chewie(controller: _chewieController!),
          ),
        );
      } else {
        return Container(
          height: _lesson!.type == LessonType.audio ? 100 : 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }
    }

    if (_lesson!.type == LessonType.pdf) {
      return _buildPdfViewer();
    }

    return _buildTextContent();
  }

  Widget _buildPdfViewer() {
    final isDownloaded = _lesson!.isDownloaded &&
        _lesson!.localPath != null &&
        File(_lesson!.localPath!).existsSync();

    return Column(
      children: [
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isDownloaded
                ? SfPdfViewer.file(File(_lesson!.localPath!))
                : SfPdfViewer.network(_lesson!.remoteUrl),
          ),
        ),
        if (!isDownloaded) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Viewing Online - Download the course for offline access',
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.article_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Lesson Content', style: AppTextStyles.heading4),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Full lesson content available via the source link below.',
                style: AppTextStyles.body.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
        if (_lesson?.remoteUrl != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 16),
              label: const Text('View full content online'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson Not Found')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    final courseAsync =
        _courseId != null ? ref.watch(courseProvider(_courseId!)) : null;
    final course = courseAsync?.value;
    final isCompleted = _lesson!.progress >= 1.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: isCompleted ? AppColors.success : context.textLight,
            ),
            onPressed: isCompleted ? null : _markLessonComplete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lesson ${_currentLessonIndex + 1}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(_lesson!.title, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _lesson!.type == LessonType.video
                      ? Icons.play_circle_outline
                      : _lesson!.type == LessonType.pdf
                          ? Icons.picture_as_pdf
                          : Icons.article_outlined,
                  size: 16,
                  color: context.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _lesson!.type.name.toUpperCase(),
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content widget
            _buildContentWidget(),

            const SizedBox(height: 24),

            // Complete Button
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markLessonComplete,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Complete Lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Lesson Completed',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Progress footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.borderColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Course Progress',
                          style: AppTextStyles.caption),
                      Text(
                        course != null
                            ? '${(course.progress * 100).toStringAsFixed(0)}%'
                            : '0%',
                        style: AppTextStyles.caption
                            .copyWith(color: context.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(
                    progress: course?.progress ?? 0.0,
                    height: 6,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _currentLessonIndex > 0
                            ? () {
                                final prevLesson =
                                    _allLessons[_currentLessonIndex - 1];
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/lesson',
                                  arguments: {
                                    'courseId': _courseId,
                                    'lessonId': prevLesson.id,
                                  },
                                );
                              }
                            : null,
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: _currentLessonIndex > 0
                                ? context.textSecondary
                                : context.textLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _currentLessonIndex < _allLessons.length - 1
                            ? () {
                                final nextLesson =
                                    _allLessons[_currentLessonIndex + 1];
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/lesson',
                                  arguments: {
                                    'courseId': _courseId,
                                    'lessonId': nextLesson.id,
                                  },
                                );
                              }
                            : null,
                        child: Row(
                          children: [
                            Text(
                              _currentLessonIndex < _allLessons.length - 1
                                  ? 'Next Lesson'
                                  : 'Complete',
                              style: TextStyle(
                                color:
                                    _currentLessonIndex < _allLessons.length - 1
                                        ? AppColors.primary
                                        : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentLessonIndex <
                                _allLessons.length - 1) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
