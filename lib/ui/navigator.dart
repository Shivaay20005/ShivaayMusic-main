import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/models/album.dart';
import 'package:shivaaymusic/models/artist.dart';

import 'package:shivaaymusic/ui/screens/Artists/artist_screen.dart';
import 'package:shivaaymusic/ui/screens/Home/home_screen.dart';
import 'package:shivaaymusic/ui/screens/Settings/pages/admin_alert_page.dart';
import 'package:shivaaymusic/ui/screens/MusicRoom/room_lobby_screen.dart';
import 'package:shivaaymusic/ui/screens/MusicRoom/music_room_screen.dart';
import 'package:shivaaymusic/ui/screens/MusicRoom/room_chat_screen.dart';

import 'screens/Album/album_screen.dart';
import 'screens/Playlist/playlist_screen.dart';
import 'screens/Search/search_result_screen.dart';
import 'screens/Search/search_screen.dart';

class ScreenNavigationSetup {
  ScreenNavigationSetup._();

  static const id = 1;
  static const homeScreen = '/homeScreen';
  static const searchScreen = '/searchScreen';
  static const searchResultScreen = '/searchResultScreen';
  static const artistScreen = '/artistScreen';
  static const albumScreen = '/albumScreen';
  static const playlistScreen = '/playlistScreen';
  static const adminAlertPage = '/adminAlertPage';
  static const musicRoomLobby = '/musicRoomLobby';
  static const musicRoom = '/musicRoom';
  static const musicRoomChat = '/musicRoomChat';
}

class ScreenNavigation extends StatelessWidget {
  const ScreenNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
        key: Get.nestedKey(ScreenNavigationSetup.id),
        initialRoute: '/homeScreen',
        onGenerateRoute: (settings) {
          Get.routing.args = settings.arguments;
          switch (settings.name) {

            case ScreenNavigationSetup.homeScreen:
              return GetPageRoute(
                  page: () => const HomeScreen(), settings: settings);
            
            case ScreenNavigationSetup.albumScreen:
              final id = (settings.arguments as (Album?, String)).$2;
              return GetPageRoute(
                  page: () => AlbumScreen(
                        key: Key(id),
                      ),
                  settings: settings);
            
            case ScreenNavigationSetup.playlistScreen:
             final id = (settings.arguments as List)[1] as String;
              return GetPageRoute(
                  page: () => PlaylistScreen(
                        key: Key(id),
                      ),
                  settings: settings);
            
            case ScreenNavigationSetup.searchScreen:
              return GetPageRoute(
                  page: () => const SearchScreen(), settings: settings);
            
            case ScreenNavigationSetup.searchResultScreen:
              return GetPageRoute(
                  page: () => const SearchResultScreen(), settings: settings);
            
            case ScreenNavigationSetup.artistScreen:
              final args = settings.arguments as List;
              final id = args[0] ? args[1] : (args[1] as Artist).browseId;
              return GetPageRoute(
                  page: () => ArtistScreen(
                        key: Key(id),
                      ),
                  settings: settings);
            
            case ScreenNavigationSetup.adminAlertPage:
              return GetPageRoute(
                  page: () => const AdminAlertPage(), settings: settings);
            
            case ScreenNavigationSetup.musicRoomLobby:
              return GetPageRoute(
                  page: () => const RoomLobbyScreen(), settings: settings);
            
            case ScreenNavigationSetup.musicRoom:
              return GetPageRoute(
                  page: () => const MusicRoomScreen(), settings: settings);
            
            case ScreenNavigationSetup.musicRoomChat:
              return GetPageRoute(
                  page: () => const RoomChatScreen(), settings: settings);

            default:
              return null;
          }
        });
  }
}
