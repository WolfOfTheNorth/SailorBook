import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import '../models/book.dart';
import '../models/voice.dart';
import '../services/audio_service.dart';
import '../generated/native.dart' as native;

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(ref.read(audioServiceProvider)),
);

class PlayerController extends StateNotifier<PlayerState> {
  final AudioService _audioService;
  BookManifest? _currentManifest;
  List<String> _prebufferedAudio = [];
  int _currentPrebufferIndex = 0;

  PlayerController(this._audioService) : super(const PlayerState()) {
    _audioService.initialize();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioService.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioService.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _audioService.playerStateStream.listen((playerState) {
      if (playerState is just_audio.PlayerState) {
        final playbackState = playerState.playing
            ? PlaybackState.playing
            : playerState.processingState == just_audio.ProcessingState.completed
                ? PlaybackState.stopped
                : PlaybackState.paused;

        state = state.copyWith(state: playbackState);

        // Auto-advance to next paragraph when current finishes
        if (playerState.processingState == just_audio.ProcessingState.completed) {
          _handleAudioCompleted();
        }
      }
    });
  }

  Future<void> loadBook(String bookId) async {
    try {
      state = state.copyWith(state: PlaybackState.loading);

      // Load manifest
      final manifestPath = await _getManifestPath(bookId);
      final manifest = await native.loadManifest(manifestPath);

      if (manifest == null) {
        throw Exception('Book manifest not found');
      }

      _currentManifest = BookManifest(
        bookId: manifest.bookId,
        title: manifest.title,
        author: manifest.author,
        chapters: manifest.chapters.map((c) => Chapter(
          id: c.id,
          title: c.title,
          paragraphIds: c.paragraphIds,
        )).toList(),
        paragraphs: manifest.paragraphs.map((p) => Paragraph(
          id: p.id,
          chapterId: p.chapterId,
          text: p.text,
          wordCount: p.wordCount,
        )).toList(),
        lastPosition: manifest.lastPosition != null
            ? PlaybackPosition(
                chapterId: manifest.lastPosition!.chapterId,
                paragraphId: manifest.lastPosition!.paragraphId,
                offsetMs: manifest.lastPosition!.offsetMs,
              )
            : null,
      );

      // Load last position or start from beginning
      final lastPosition = _currentManifest!.lastPosition;
      final startParagraphId = lastPosition?.paragraphId ?? 0;
      final startChapterId = lastPosition?.chapterId ?? 0;

      state = state.copyWith(
        currentBookId: bookId,
        currentChapterId: startChapterId,
        currentParagraphId: startParagraphId,
        state: PlaybackState.stopped,
      );
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
      );
      throw Exception('Failed to load book: $e');
    }
  }

  Future<void> play() async {
    if (_currentManifest == null) return;

    try {
      final currentParagraph = _getCurrentParagraph();
      if (currentParagraph == null) return;

      state = state.copyWith(state: PlaybackState.loading);

      // Generate audio for current paragraph
      final audioPath = await _audioService.generateAudio(
        currentParagraph.text,
        state.voiceConfig,
      );

      // Prebuffer next paragraphs
      await _prebufferNextParagraphs();

      // Play current paragraph
      await _audioService.playAudioFile(audioPath);

      state = state.copyWith(state: PlaybackState.playing);
    } catch (e) {
      state = state.copyWith(state: PlaybackState.error);
    }
  }

  Future<void> pause() async {
    await _audioService.pause();
    state = state.copyWith(state: PlaybackState.paused);
  }

  Future<void> resume() async {
    await _audioService.resume();
    state = state.copyWith(state: PlaybackState.playing);
  }

  Future<void> stop() async {
    await _audioService.stop();
    state = state.copyWith(
      state: PlaybackState.stopped,
      position: Duration.zero,
    );
  }

  Future<void> nextParagraph() async {
    final currentParagraph = _getCurrentParagraph();
    if (currentParagraph == null) return;

    final nextParagraphId = currentParagraph.id + 1;
    final nextParagraph = _currentManifest!.paragraphs
        .where((p) => p.id == nextParagraphId)
        .firstOrNull;

    if (nextParagraph != null) {
      state = state.copyWith(
        currentParagraphId: nextParagraph.id,
        currentChapterId: nextParagraph.chapterId,
        position: Duration.zero,
      );

      if (state.state == PlaybackState.playing) {
        await _playPrebufferedOrGenerate();
      }
    }
  }

  Future<void> previousParagraph() async {
    final currentParagraph = _getCurrentParagraph();
    if (currentParagraph == null) return;

    final prevParagraphId = currentParagraph.id - 1;
    if (prevParagraphId >= 0) {
      final prevParagraph = _currentManifest!.paragraphs
          .where((p) => p.id == prevParagraphId)
          .firstOrNull;

      if (prevParagraph != null) {
        state = state.copyWith(
          currentParagraphId: prevParagraph.id,
          currentChapterId: prevParagraph.chapterId,
          position: Duration.zero,
        );

        if (state.state == PlaybackState.playing) {
          await play(); // Regenerate audio for previous paragraph
        }
      }
    }
  }

  Future<void> seekBack(Duration duration) async {
    final newPosition = state.position - duration;
    final seekPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
    await _audioService.seek(seekPosition);
  }

  Future<void> setSpeed(double speed) async {
    await _audioService.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> setVoiceConfig(VoiceConfig config) async {
    state = state.copyWith(voiceConfig: config);
    
    // Clear prebuffered audio since voice changed
    _prebufferedAudio.clear();
    _currentPrebufferIndex = 0;
  }

  Future<void> savePosition() async {
    if (_currentManifest == null || state.currentBookId == null) return;

    final position = native.Position(
      chapterId: state.currentChapterId!,
      paragraphId: state.currentParagraphId!,
      offsetMs: state.position.inMilliseconds,
    );

    final manifestPath = await _getManifestPath(state.currentBookId!);
    await native.updateLastPosition(manifestPath, position);
  }

  Paragraph? _getCurrentParagraph() {
    if (_currentManifest == null || state.currentParagraphId == null) {
      return null;
    }

    return _currentManifest!.paragraphs
        .where((p) => p.id == state.currentParagraphId!)
        .firstOrNull;
  }

  Future<void> _prebufferNextParagraphs() async {
    final currentParagraphId = state.currentParagraphId ?? 0;
    const prebufferCount = 3;

    final nextParagraphs = _currentManifest!.paragraphs
        .where((p) => p.id > currentParagraphId)
        .take(prebufferCount)
        .toList();

    if (nextParagraphs.isNotEmpty) {
      final texts = nextParagraphs.map((p) => p.text).toList();
      _prebufferedAudio = await _audioService.prebufferAudio(
        texts,
        state.voiceConfig,
        prebufferCount,
      );
      _currentPrebufferIndex = 0;
    }
  }

  Future<void> _playPrebufferedOrGenerate() async {
    if (_currentPrebufferIndex < _prebufferedAudio.length) {
      // Use prebuffered audio
      final audioPath = _prebufferedAudio[_currentPrebufferIndex];
      await _audioService.playAudioFile(audioPath);
      _currentPrebufferIndex++;
    } else {
      // Generate new audio
      await play();
    }
  }

  void _handleAudioCompleted() {
    // Auto-advance to next paragraph
    nextParagraph();
  }

  Future<String> _getManifestPath(String bookId) async {
    // This would normally use path_provider to get the correct path
    return '/data/books/$bookId/manifest.json';
  }

  @override
  void dispose() {
    _audioService.dispose();
    savePosition();
    super.dispose();
  }
}