import 'dart:typed_data';
import 'dart:io';
import 'package:just_audio/just_audio.dart' as just_audio hide PlayerState;
import 'package:path_provider/path_provider.dart';
import '../models/voice.dart';
import '../generated/native.dart' as native;

class AudioService {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  final Map<String, String> _audioCache = {};
  
  just_audio.AudioPlayer get player => _player;
  
  Future<void> initialize() async {
    // Initialize audio session
    await _player.setVolume(1.0);
  }
  
  Future<String> generateAudio(String text, VoiceConfig voiceConfig) async {
    final cacheKey = native.cacheKeyFor(text, _voiceConfigToNative(voiceConfig));
    
    // Check if audio is already cached
    if (_audioCache.containsKey(cacheKey)) {
      return _audioCache[cacheKey]!;
    }
    
    // Generate audio using native TTS
    final audioData = await native.synthesize(text, _voiceConfigToNative(voiceConfig));
    
    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final audioFile = File('${tempDir.path}/audio_$cacheKey.wav');
    await audioFile.writeAsBytes(Uint8List.fromList(audioData));
    
    final filePath = audioFile.path;
    _audioCache[cacheKey] = filePath;
    
    return filePath;
  }
  
  Future<List<String>> prebufferAudio(
    List<String> texts,
    VoiceConfig voiceConfig,
    int count,
  ) async {
    final audioDataList = await native.prebuffer(
      texts,
      _voiceConfigToNative(voiceConfig),
      count,
    );
    
    final List<String> filePaths = [];
    final tempDir = await getTemporaryDirectory();
    
    for (int i = 0; i < audioDataList.length; i++) {
      final audioData = audioDataList[i];
      final cacheKey = native.cacheKeyFor(texts[i], _voiceConfigToNative(voiceConfig));
      final audioFile = File('${tempDir.path}/audio_$cacheKey.wav');
      
      await audioFile.writeAsBytes(Uint8List.fromList(audioData));
      filePaths.add(audioFile.path);
      _audioCache[cacheKey] = audioFile.path;
    }
    
    return filePaths;
  }
  
  Future<void> playAudioFile(String filePath) async {
    try {
      await _player.setAudioSource(just_audio.AudioSource.uri(Uri.file(filePath)));
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }
  
  Future<void> pause() async {
    await _player.pause();
  }
  
  Future<void> resume() async {
    await _player.play();
  }
  
  Future<void> stop() async {
    await _player.stop();
  }
  
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }
  
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Object?> get playerStateStream => _player.playerStateStream;
  
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  
  Future<void> dispose() async {
    await _player.dispose();
    
    // Clean up cache files
    for (final filePath in _audioCache.values) {
      try {
        await File(filePath).delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }
    _audioCache.clear();
  }
  
  native.VoiceCfg _voiceConfigToNative(VoiceConfig config) {
    return native.VoiceCfg(
      id: config.id,
      rate: config.rate,
      pitch: config.pitch,
    );
  }
}