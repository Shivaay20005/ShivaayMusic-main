import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../../ui/player/player_controller.dart';

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.titleLarge?.color;

    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/icon.png',
            width: GetPlatform.isAndroid ? 56 : 45,
            height: GetPlatform.isAndroid ? 60 : 48,
          ),
          const SizedBox(width: 12),
          Text(
            'ShivaayMusic',
            style: GoogleFonts.dancingScript(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_rounded,
            color: titleColor,
            size: 24,
          ),
          tooltip: "Share",
          onPressed: () => _onSharePressed(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Handles the share button press
  void _onSharePressed(BuildContext context) {
    // Check if there's a currently playing song
    final playerController = Get.find<PlayerController>();
    final currentSong = playerController.currentSong.value;
    
    if (currentSong != null) {
      // Share the currently playing song
      final songLink = "https://shivaaymusic.netlify.app/watch?v=${currentSong.id}";
      final songTitle = currentSong.title;
      final artistName = currentSong.artist ?? "Unknown Artist";
      
      final shareText = '🎧 Check out this amazing song I\'m listening to on ShivaayMusic!\n\n'
          '"$songTitle" by $artistName\n\n'
          'Listen to it here: $songLink\n\n'
          'Download ShivaayMusic for FREE - No Ads, High Quality Music Streaming!\n'
          'https://shivaaymusic.netlify.app/';
      
      Share.share(shareText);
    } else {
      // Share the general app link
      const String shareText = '🎧🔥 Tired of ads ruining your music vibe?\n\n'
          '🎶 Dive into pure music bliss with ShivaayMusic – your FREE high-quality music streaming app with ZERO ADS!\n\n'
          'Whether you\'re chilling, working, or vibing solo – ShivaayMusic has the perfect track for every mood.\n\n'
          '𝘿𝙤𝙬𝙣𝙡𝙤𝙖𝙙 ShivaayMusic 𝘼𝙥𝙥 𝙛𝙧𝙤𝙢 𝙝𝙚𝙧𝙚 👇👇 \n\n'
          'https://shivaaymusic.netlify.app/\n\n'
          '🎵 No Ads.\n\n'
          '🎵 High Quality.\n\n'
          '🎵 100% Free.\n\n'
          '✨ Let the music chill your soul – Share the vibe with your friends! 🔁💙';
      
      Share.share(shareText);
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}