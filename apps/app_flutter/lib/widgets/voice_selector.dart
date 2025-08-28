import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/voice.dart';

class VoiceSelector extends StatefulWidget {
  final VoiceConfig currentConfig;
  final Function(VoiceConfig) onConfigChanged;

  const VoiceSelector({
    super.key,
    required this.currentConfig,
    required this.onConfigChanged,
  });

  @override
  State<VoiceSelector> createState() => _VoiceSelectorState();
}

class _VoiceSelectorState extends State<VoiceSelector> {
  late VoiceConfig _config;

  final List<VoiceInfo> _availableVoices = const [
    VoiceInfo(
      id: 'en_us_default',
      name: 'English (US) - Default',
      language: 'en-US',
      description: 'Standard American English voice',
    ),
    VoiceInfo(
      id: 'en_us_female',
      name: 'English (US) - Female',
      language: 'en-US',
      description: 'Female American English voice',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          // Voice selection
          Text(
            'Voice',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Expanded(
            child: ListView.builder(
              itemCount: _availableVoices.length,
              itemBuilder: (context, index) {
                final voice = _availableVoices[index];
                final isSelected = voice.id == _config.id;
                
                return Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.record_voice_over,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(voice.name),
                    subtitle: Text(voice.description),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => _updateVoice(voice.id),
                  ),
                );
              },
            ),
          ),
          
          // Speed control
          Text(
            'Speaking Rate',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Slower'),
                      Text(
                        '${_config.rate.toStringAsFixed(1)}×',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Faster'),
                    ],
                  ),
                  
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _config.rate,
                      min: 0.5,
                      max: 2.5,
                      divisions: 20,
                      onChanged: (value) => _updateRate(value),
                    ),
                  ),
                  
                  // Speed presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [0.8, 1.0, 1.25, 1.5, 2.0].map((speed) {
                      final isSelected = (_config.rate - speed).abs() < 0.01;
                      return ActionChip(
                        label: Text('$speed×'),
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                        onPressed: () => _updateRate(speed),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Pitch control
          Text(
            'Pitch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lower'),
                      Text(
                        _config.pitch.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Higher'),
                    ],
                  ),
                  
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _config.pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (value) => _updatePitch(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applySettings,
              child: const Text('Apply Settings'),
            ),
          ),
        ],
      ),
    );
  }

  void _updateVoice(String voiceId) {
    setState(() {
      _config = _config.copyWith(id: voiceId);
    });
  }

  void _updateRate(double rate) {
    setState(() {
      _config = _config.copyWith(rate: rate);
    });
  }

  void _updatePitch(double pitch) {
    setState(() {
      _config = _config.copyWith(pitch: pitch);
    });
  }

  void _applySettings() {
    widget.onConfigChanged(_config);
    Navigator.of(context).pop();
  }
}