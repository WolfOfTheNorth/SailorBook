import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/voice.dart';

class PlayerControls extends StatelessWidget {
  final PlayerState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSeekBack;

  const PlayerControls({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onPrevious,
    required this.onNext,
    required this.onSeekBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous paragraph
            _buildControlButton(
              context,
              Icons.skip_previous,
              'Previous',
              onPrevious,
            ),
            
            // Seek back 10s
            _buildControlButton(
              context,
              Icons.replay_10,
              'Back 10s',
              onSeekBack,
            ),
            
            // Play/Pause
            _buildMainPlayButton(context),
            
            // Next paragraph
            _buildControlButton(
              context,
              Icons.skip_next,
              'Next',
              onNext,
            ),
            
            // Stop
            _buildControlButton(
              context,
              Icons.stop,
              'Stop',
              onStop,
              isEnabled: state.state != PlaybackState.stopped,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainPlayButton(BuildContext context) {
    final isPlaying = state.state == PlaybackState.playing;
    final isLoading = state.state == PlaybackState.loading;
    
    return Container(
      width: 72.w,
      height: 72.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36.r),
          onTap: isLoading ? null : (isPlaying ? onPause : onPlay),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32.sp,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isEnabled = true,
  }) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: isEnabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24.r),
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: Icon(
              icon,
              size: 24.sp,
              color: isEnabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}