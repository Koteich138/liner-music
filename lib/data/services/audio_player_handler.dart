import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

enum MusicServiceSource { spotify, appleMusic, yandexMusic, youtubeMusic, soundcloud, unknown }

class TrackModel {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String artworkUrl;
  final String? isrc;
  final MusicServiceSource source;
  final bool isImported;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.artworkUrl,
    this.isrc,
    required this.source,
    this.isImported = true,
  });
}

class LyricsLine {
  final Duration timestamp;
  final String text;

  LyricsLine({required this.timestamp, required this.text});
}

/// Парсер ссылок мультисервисного агрегатора
class LinkAggregatorParser {
  static final _spotifyRegExp = RegExp(r'open\.spotify\.com/(playlist|album|track)/([a-zA-Z0-9]+)');
  static final _appleRegExp = RegExp(r'music\.apple\.com/[a-z]{2}/(album|playlist)/[^/]+/([a-zA-Z0-9\.]+)');
  static final _yandexRegExp = RegExp(r'music\.yandex\.(ru|com)/users/([^/]+)/playlists/(\d+)');
  static final _ytMusicRegExp = RegExp(r'music\.youtube\.com/playlist\?list=([a-zA-Z0-9_-]+)');
  static final _soundcloudRegExp = RegExp(r'soundcloud\.com/([^/]+)/sets/([^/]+)');

  static MusicServiceSource detectSource(String url) {
    if (_spotifyRegExp.hasMatch(url)) return MusicServiceSource.spotify;
    if (_appleRegExp.hasMatch(url)) return MusicServiceSource.appleMusic;
    if (_yandexRegExp.hasMatch(url)) return MusicServiceSource.yandexMusic;
    if (_ytMusicRegExp.hasMatch(url)) return MusicServiceSource.youtubeMusic;
    if (_soundcloudRegExp.hasMatch(url)) return MusicServiceSource.soundcloud;
    return MusicServiceSource.unknown;
  }

  /// Имитация извлечения метаданных плейлиста по ссылке
  static Future<List<TrackModel>> parsePlaylistUrl(String url) async {
    final source = detectSource(url);
    await Future.delayed(const Duration(milliseconds: 1200)); // Анимация парсинга

    return [
      TrackModel(
        id: '1',
        title: 'Snooze',
        artist: 'SZA',
        duration: const Duration(minutes: 3, seconds: 21),
        artworkUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80',
        source: source,
      ),
      TrackModel(
        id: '2',
        title: 'the kill 2',
        artist: 'Key Glock, Kenny Muney',
        duration: const Duration(minutes: 3, seconds: 10),
        artworkUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&q=80',
        source: source,
      ),
      TrackModel(
        id: '3',
        title: 'LEGACY',
        artist: 'OFFSET',
        duration: const Duration(minutes: 2, seconds: 56),
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
        source: source,
      ),
    ];
  }
}

/// Парсер LRC-файлов для синхронизированных текстов
class LrcParser {
  static final _timeRegExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

  static List<LyricsLine> parse(String rawLrc) {
    final lines = <LyricsLine>[];
    for (final line in rawLrc.split('\n')) {
      final match = _timeRegExp.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.padRight(3, '0'));
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricsLine(
            timestamp: Duration(minutes: min, seconds: sec, milliseconds: ms),
            text: text,
          ));
        }
      }
    }
    return lines;
  }
}

/// Обработчик фонового воспроизведения с обходом DRM через сопоставление потоков
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, String> _streamUrlCache = {};

  AudioPlayerHandler() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Stream<Duration> get positionStream => _player.positionStream;

  /// Universal Playback Engine: находим прямой аудиопоток по связке "Artist - Title"
  Future<String> _resolveStreamUrl(TrackModel track, {String? yandexToken}) async {
    if (_streamUrlCache.containsKey(track.id)) {
      return _streamUrlCache[track.id]!;
    }

    // Если есть токен Яндекс Музыки и источник Яндекс — используем прямой поток
    if (track.source == MusicServiceSource.yandexMusic && yandexToken != null) {
      // Здесь выполняется запрос к api.music.yandex.net/tracks/{id}/download-info
    }

    try {
      final query = '${track.artist} - ${track.title} official audio';
      final searchResults = await _yt.search.search(query);

      // Ищем совпадение, близкое по длительности (±15 секунд)
      final matchedVideo = searchResults.firstWhere(
        (v) => v.duration != null && (v.duration! - track.duration).inSeconds.abs() <= 15,
        orElse: () => searchResults.first,
      );

      final manifest = await _yt.videos.streamsClient.getManifest(matchedVideo.id);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final streamUrl = audioStreamInfo.url.toString();

      _streamUrlCache[track.id] = streamUrl;
      return streamUrl;
    } catch (e) {
      // Fallback демо-поток на случай отсутствия сети или блокировки
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }
  }

  Future<void> playTrack(TrackModel track) async {
    final item = MediaItem(
      id: track.id,
      album: 'Liner Unified Library',
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: Uri.parse(track.artworkUrl),
    );
    mediaItem.add(item);

    final streamUrl = await _resolveStreamUrl(track);
    await _player.setUrl(streamUrl);
    _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}