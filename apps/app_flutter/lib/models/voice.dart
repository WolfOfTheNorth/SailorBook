import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice.g.dart';

@JsonSerializable()
class VoiceConfig extends Equatable {
  final String id;
  final double rate;
  final double pitch;

  const VoiceConfig({
    required this.id,
    this.rate = 1.0,
    this.pitch = 1.0,
  });

  factory VoiceConfig.fromJson(Map<String, dynamic> json) => 
      _$VoiceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceConfigToJson(this);

  static const VoiceConfig defaultConfig = VoiceConfig(
    id: 'en_us_default',
    rate: 1.0,
    pitch: 1.0,
  );

  VoiceConfig copyWith({
    String? id,
    double? rate,
    double? pitch,
  }) {
    return VoiceConfig(
      id: id ?? this.id,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
    );
  }

  @override
  List<Object?> get props => [id, rate, pitch];
}

@JsonSerializable()
class VoiceInfo extends Equatable {
  final String id;
  final String name;
  final String language;
  final String description;
  final String? modelPath;

  const VoiceInfo({
    required this.id,
    required this.name,
    required this.language,
    required this.description,
    this.modelPath,
  });

  factory VoiceInfo.fromJson(Map<String, dynamic> json) => 
      _$VoiceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceInfoToJson(this);

  @override
  List<Object?> get props => [id, name, language, description, modelPath];
}

enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

@JsonSerializable()
class PlayerState extends Equatable {
  final PlaybackState state;
  final String? currentBookId;
  final int? currentChapterId;
  final int? currentParagraphId;
  final Duration position;
  final Duration duration;
  final double speed;
  final VoiceConfig voiceConfig;

  const PlayerState({
    this.state = PlaybackState.stopped,
    this.currentBookId,
    this.currentChapterId,
    this.currentParagraphId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.voiceConfig = VoiceConfig.defaultConfig,
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) => 
      _$PlayerStateFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerStateToJson(this);

  PlayerState copyWith({
    PlaybackState? state,
    String? currentBookId,
    int? currentChapterId,
    int? currentParagraphId,
    Duration? position,
    Duration? duration,
    double? speed,
    VoiceConfig? voiceConfig,
  }) {
    return PlayerState(
      state: state ?? this.state,
      currentBookId: currentBookId ?? this.currentBookId,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      currentParagraphId: currentParagraphId ?? this.currentParagraphId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      voiceConfig: voiceConfig ?? this.voiceConfig,
    );
  }

  @override
  List<Object?> get props => [
        state,
        currentBookId,
        currentChapterId,
        currentParagraphId,
        position,
        duration,
        speed,
        voiceConfig,
      ];
}