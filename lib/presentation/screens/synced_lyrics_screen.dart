import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/ui/glass_components.dart';
import '../../data/services/audio_player_handler.dart';

class SyncedLyricsScreen extends StatefulWidget {
  final TrackModel track;
  final AudioPlayerHandler audioHandler;
  final List<LyricsLine> lyrics;

  const SyncedLyricsScreen({
    super.key,
    required this.track,
    required this.audioHandler,
    required this.lyrics,
  });

  @override
  State<SyncedLyricsScreen> createState() => _SyncedLyricsScreenState();
}

class _SyncedLyricsScreenState extends State<SyncedLyricsScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  int _activeLineIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return DynamicBackgroundWrapper(
      imageUrl: widget.track.artworkUrl,
      child: StreamBuilder<Duration>(
        stream: widget.audioHandler.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          _updateActiveLine(position);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Верхний бар закрытия
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    GlassContainer(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: const Text(
                        'Lyrics Sync • 0.00s',
                        style: TextStyle(color: LinerColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(flex: 4, child: _buildTrackPanel(position)),
                            const SizedBox(width: 32),
                            Expanded(flex: 6, child: _buildLyricsList()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCompactTrackHeader(position),
                            const SizedBox(height: 24),
                            Expanded(child: _buildLyricsList()),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateActiveLine(Duration position) {
    int newIndex = 0;
    for (int i = 0; i < widget.lyrics.length; i++) {
      if (position >= widget.lyrics[i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (newIndex != _activeLineIndex) {
      _activeLineIndex = newIndex;
      if (_scrollController.isAttached) {
        _scrollController.scrollTo(
          index: _activeLineIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.38,
        );
      }
    }
  }

  Widget _buildTrackPanel(Duration position) {
    final total = widget.track.duration.inSeconds.toDouble();
    final current = position.inSeconds.toDouble().clamp(0.0, total);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: widget.track.artworkUrl,
            width: 280,
            height: 280,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track.artist,
                  style: const TextStyle(color: LinerColors.textSecondary, fontSize: 15),
                ),
              ],
            ),
            const Icon(Icons.check, color: LinerColors.textSecondary),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          ),
          child: Slider(
            value: current,
            max: total > 0 ? total : 1,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: (val) {
              widget.audioHandler.seek(Duration(seconds: val.toInt()));
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 42),
              onPressed: () => widget.audioHandler.pause(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactTrackHeader(Duration position) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.track.artworkUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.track.artist,
                  style: const TextStyle(color: LinerColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            onPressed: () => widget.audioHandler.play(),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList() {
    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics[index];
        final isActive = index == _activeLineIndex;
        final distance = (index - _activeLineIndex).abs();
        final opacity = isActive ? 1.0 : (0.45 - (distance * 0.08)).clamp(0.15, 0.45);

        return GestureDetector(
          onTap: () => widget.audioHandler.seek(line.timestamp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: isActive ? 26.0 : 21.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white.withOpacity(opacity),
                shadows: isActive
                    ? [
                        Shadow(
                          color: Colors.white.withOpacity(0.55),
                          blurRadius: 18,
                        )
                      ]
                    : [],
              ),
              child: Text(line.text),
            ),
          ),
        );
      },
    );
  }
}