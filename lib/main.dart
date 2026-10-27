import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'core/ui/glass_components.dart';
import 'data/services/audio_player_handler.dart';
import 'presentation/screens/synced_lyrics_screen.dart';

late AudioPlayerHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.liner.music.channel.audio',
      androidNotificationChannelName: 'Liner Music Playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(const LinerApp());
}

class LinerApp extends StatelessWidget {
  const LinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: LinerColors.background,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentCover = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80';
  late TrackModel _currentTrack;

  final List<Map<String, String>> _mixes = [
    {'title': 'Daily Mix 1', 'sub': 'SZA, Kali Uchis, Daniel Caesar', 'color': '0xFF8B4513'},
    {'title': 'Daily Mix 2', 'sub': 'VILLIAN, madk1d, 17 SEVENTEEN', 'color': '0xFF4A2545'},
    {'title': 'Daily Mix 3', 'sub': 'greyrock, tewiq, फाल्गुन', 'color': '0xFF5A1818'},
    {'title': 'Daily Mix 4', 'sub': 'Skryptonite, Kizaru, Friendly Thug', 'color': '0xFF8C7A3E'},
  ];

  final List<Map<String, String>> _topAlbums = [
    {
      'title': 'Красивое Зло',
      'artist': 'VILLIAN',
      'cover': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&q=80'
    },
    {
      'title': 'SOS',
      'artist': 'SZA',
      'cover': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80'
    },
    {
      'title': 'Currents',
      'artist': 'Tame Impala',
      'cover': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80'
    },
    {
      'title': 'AM',
      'artist': 'Arctic Monkeys',
      'cover': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentTrack = TrackModel(
      id: 'snooze_1',
      title: 'Snooze',
      artist: 'SZA',
      duration: const Duration(minutes: 3, seconds: 21),
      artworkUrl: _currentCover,
      source: MusicServiceSource.spotify,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBackgroundWrapper(
      imageUrl: _currentCover,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopNavigation()),
              SliverToBoxAdapter(child: _buildYourMixesSection()),
              SliverToBoxAdapter(child: _buildTopAlbumsSection()),
              SliverToBoxAdapter(child: _buildListeningNowSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomMiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.waves_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Liner',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _showImportModal,
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.link_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Import Playlist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: _showYouTubeSettingsModal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourMixesSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Mixes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mixes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final mix = _mixes[index];
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 135,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 115,
                          width: 135,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Color(int.parse(mix['color']!)),
                          ),
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'MIX ${index + 1}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(mix['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          mix['sub']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: LinerColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAlbumsSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Albums', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topAlbums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final album = _topAlbums[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentCover = album['cover']!);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: album['cover']!,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(album['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        album['artist']!,
                        style: const TextStyle(color: LinerColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningNowSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Listening right now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildTrackTile('the kill 2', 'Key Glock, Kenny Muney', '3:10'),
                _buildTrackTile('LEGACY', 'OFFSET', '2:56'),
                _buildTrackTile('Snooze', 'SZA', '3:21'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(String title, String artist, String duration) {
    return ListTile(
      onTap: () => _audioHandler.playTrack(_currentTrack),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(imageUrl: _currentCover, width: 44, height: 44, fit: BoxFit.cover),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(artist, style: const TextStyle(color: LinerColors.textSecondary, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: LinerColors.spotifyNeon, size: 18),
          const SizedBox(width: 12),
          Text(duration, style: const TextStyle(color: LinerColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomMiniPlayer() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: GestureDetector(
        onTap: _openSyncedLyrics,
        child: GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: _currentTrack.artworkUrl,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentTrack.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _currentTrack.artist,
                      style: const TextStyle(color: LinerColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lyrics_outlined, color: Colors.white70),
                onPressed: _openSyncedLyrics,
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                onPressed: () => _audioHandler.playTrack(_currentTrack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSyncedLyrics() {
    const sampleLrc = '''
[00:00.00]Long as you dreamin' 'bout me, ain't no problem
[00:04.50]I don't got nobody, just with you right now
[00:09.00]Tell the truth, I look better under you
[00:13.50]I can't lose when I'm with you
[00:18.00]How can I snooze and miss the moment?
[00:22.50]You just too important
[00:27.00]Nobody do body like you do
[00:31.50]I can't lose when I'm with you
[00:36.00]I can't just snooze and miss the moment
''';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyncedLyricsScreen(
          track: _currentTrack,
          audioHandler: _audioHandler,
          lyrics: LrcParser.parse(sampleLrc),
        ),
      ),
    );
  }

  /// Модальное окно импорта: «Paste a link. Bring your playlist.»
  void _showImportModal() {
    final controller = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Paste a link. Bring your playlist.',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Светящиеся неоновые иконки сервисов
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.speaker_group, color: LinerColors.spotifyNeon, size: 28),
                        Icon(Icons.cloud, color: LinerColors.soundcloudNeon, size: 28),
                        Icon(Icons.play_circle_fill, color: LinerColors.youtubeNeon, size: 28),
                        Icon(Icons.music_note, color: LinerColors.appleNeon, size: 28),
                        Icon(Icons.favorite, color: Colors.purpleAccent, size: 28),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GlassContainer(
                      borderRadius: 30,
                      padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: LinerColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'open.spotify.com/playlist/...',
                                hintStyle: TextStyle(color: LinerColors.textSecondary),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setModalState(() => isLoading = true);
                                    final tracks = await LinkAggregatorParser.parsePlaylistUrl(
                                      controller.text,
                                    );
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          content: GlassContainer(
                                            borderRadius: 30,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            glowColor: LinerColors.spotifyNeon,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: LinerColors.spotifyNeon,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  '${tracks.length} tracks imported',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Окно настроек и авторизации YouTube («Sign in with YouTube»)
  void _showYouTubeSettingsModal() {
    bool playThroughAccount = true;
    bool askToSignIn = true;
    bool syncLibrary = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YouTube',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'Sign in to your YouTube account to prevent playback errors.',
                      style: TextStyle(color: LinerColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: LinerColors.youtubeNeon,
                                radius: 16,
                                child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('YouTube connected', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Active session', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Play through your account', style: TextStyle(fontSize: 14)),
                      value: playThroughAccount,
                      activeColor: Colors.white,
                      onChanged: (v) => setDialogState(() => playThroughAccount = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ask to sign in', style: TextStyle(fontSize: 14)),
                      value: askToSignIn,
                      activeColor: Colors.white,
                      onChanged: (v) => setDialogState(() => askToSignIn = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sync library', style: TextStyle(fontSize: 14)),
                      value: syncLibrary,
                      activeColor: Colors.white,
                      onChanged: (v) => setDialogState(() => syncLibrary = v),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}