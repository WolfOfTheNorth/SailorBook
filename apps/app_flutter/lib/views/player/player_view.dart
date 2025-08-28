import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/player_controller.dart';
import '../../models/voice.dart';
import '../../widgets/player_controls.dart';
import '../../widgets/voice_selector.dart';

class PlayerView extends ConsumerStatefulWidget {
  final String bookId;

  const PlayerView({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<PlayerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerControllerProvider.notifier).loadBook(widget.bookId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            onPressed: () => _showVoiceSelector(context, playerController),
          ),
        ],
      ),
      body: _buildPlayerBody(playerState, playerController),
    );
  }

  Widget _buildPlayerBody(PlayerState state, PlayerController controller) {
    if (state.state == PlaybackState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading book...'),
          ],
        ),
      );
    }

    if (state.state == PlaybackState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading book',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Please try again'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadBook(widget.bookId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Book info section
        Expanded(
          flex: 3,
          child: _buildBookInfoSection(state),
        ),
        
        // Player controls section
        _buildPlayerControlsSection(state, controller),
        
        // Bottom padding for safe area
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
      ],
    );
  }

  Widget _buildBookInfoSection(PlayerState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Book cover placeholder
          Container(
            width: 200.w,
            height: 200.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.book,
              size: 80.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: 32.h),
          
          // Current paragraph text
          if (state.currentParagraphId != null) ...[
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Chapter ${(state.currentChapterId ?? 0) + 1} • Paragraph ${(state.currentParagraphId ?? 0) + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _getCurrentParagraphText(state),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Ready to play',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerControlsSection(PlayerState state, PlayerController controller) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Progress bar
          _buildProgressBar(state, controller),
          
          SizedBox(height: 24.h),
          
          // Main player controls
          PlayerControls(
            state: state,
            onPlay: controller.play,
            onPause: controller.pause,
            onStop: controller.stop,
            onPrevious: controller.previousParagraph,
            onNext: controller.nextParagraph,
            onSeekBack: () => controller.seekBack(const Duration(seconds: 10)),
          ),
          
          SizedBox(height: 24.h),
          
          // Speed control
          _buildSpeedControl(state, controller),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state, PlayerController controller) {
    return Column(
      children: [
        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(state.position),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatDuration(state.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: state.duration.inMilliseconds > 0
                ? state.position.inMilliseconds / state.duration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * state.duration.inMilliseconds).round(),
              );
              // controller.seek(newPosition); // TODO: Implement seek
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControl(PlayerState state, PlayerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Speed:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(width: 16.w),
        ...List.generate(5, (index) {
          final speeds = [0.8, 1.0, 1.25, 1.5, 2.0];
          final speed = speeds[index];
          final isSelected = (state.speed - speed).abs() < 0.01;
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ActionChip(
              label: Text('$speed×'),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
              onPressed: () => controller.setSpeed(speed),
            ),
          );
        }),
      ],
    );
  }

  String _getCurrentParagraphText(PlayerState state) {
    // This would normally fetch the actual paragraph text
    // For now, return a placeholder
    return 'Current paragraph text would be displayed here. '
           'This is paragraph ${(state.currentParagraphId ?? 0) + 1} '
           'of chapter ${(state.currentChapterId ?? 0) + 1}.';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showVoiceSelector(BuildContext context, PlayerController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VoiceSelector(
        currentConfig: ref.watch(playerControllerProvider).voiceConfig,
        onConfigChanged: controller.setVoiceConfig,
      ),
    );
  }
}