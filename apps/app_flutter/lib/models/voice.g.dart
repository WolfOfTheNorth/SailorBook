// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceConfig _$VoiceConfigFromJson(Map<String, dynamic> json) => VoiceConfig(
      id: json['id'] as String,
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$VoiceConfigToJson(VoiceConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rate': instance.rate,
      'pitch': instance.pitch,
    };

VoiceInfo _$VoiceInfoFromJson(Map<String, dynamic> json) => VoiceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      description: json['description'] as String,
      modelPath: json['modelPath'] as String?,
    );

Map<String, dynamic> _$VoiceInfoToJson(VoiceInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'language': instance.language,
      'description': instance.description,
      'modelPath': instance.modelPath,
    };

PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) => PlayerState(
      state: $enumDecodeNullable(_$PlaybackStateEnumMap, json['state']) ??
          PlaybackState.stopped,
      currentBookId: json['currentBookId'] as String?,
      currentChapterId: (json['currentChapterId'] as num?)?.toInt(),
      currentParagraphId: (json['currentParagraphId'] as num?)?.toInt(),
      position: json['position'] == null
          ? Duration.zero
          : Duration(microseconds: (json['position'] as num).toInt()),
      duration: json['duration'] == null
          ? Duration.zero
          : Duration(microseconds: (json['duration'] as num).toInt()),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      voiceConfig: json['voiceConfig'] == null
          ? VoiceConfig.defaultConfig
          : VoiceConfig.fromJson(json['voiceConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlayerStateToJson(PlayerState instance) =>
    <String, dynamic>{
      'state': _$PlaybackStateEnumMap[instance.state]!,
      'currentBookId': instance.currentBookId,
      'currentChapterId': instance.currentChapterId,
      'currentParagraphId': instance.currentParagraphId,
      'position': instance.position.inMicroseconds,
      'duration': instance.duration.inMicroseconds,
      'speed': instance.speed,
      'voiceConfig': instance.voiceConfig,
    };

const _$PlaybackStateEnumMap = {
  PlaybackState.stopped: 'stopped',
  PlaybackState.playing: 'playing',
  PlaybackState.paused: 'paused',
  PlaybackState.loading: 'loading',
  PlaybackState.error: 'error',
};
