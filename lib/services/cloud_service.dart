import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/playlist.dart';
import '../models/listening_stat.dart';
import 'listening_stats_service.dart';

import '../ui/screens/Library/library_controller.dart';
import 'package:shivaaymusic/ui/utils/theme_controller.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '../utils/helper.dart';

import 'package:package_info_plus/package_info_plus.dart';

class CloudService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  // Maintenance & Force Update Logic
  final RxBool isMaintenanceMode = false.obs;
  final RxBool isForceUpdate = false.obs;
  final RxMap<String, dynamic> maintenanceConfig = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToSystemConfig();
    _listenToAlertsAndPolls(); // Restore Broadcast & Polls
  }

  void _listenToSystemConfig() {
    _firestore.collection('system').doc('config').snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        
        // 1. Check Maintenance Mode
        if (data.containsKey('maintenanceMode')) {
          isMaintenanceMode.value = data['maintenanceMode'] == true;
        }

        // 2. Check Force Update (Only if enabled)
        bool checkUpdate = data['enableForceUpdate'] == true;
        if (checkUpdate && data.containsKey('minVersion')) {
          await _checkMinVersion(data['minVersion']);
        } else {
           isForceUpdate.value = false;
        }
        
        maintenanceConfig.value = data;

        maintenanceConfig.value = data;
      }
    }, onError: (e) {
      printERROR("System Config Listen Error: $e");
    });
  }

  // --- Restored & Safe Broadcast/Poll Logic ---

  void _listenToAlertsAndPolls() {
    // 1. Broadcast Listener
    _firestore.collection('alerts').doc('global').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['active'] == true) {
           // Delay to ensure context is ready
           Future.delayed(const Duration(seconds: 3), () {
             if (Get.overlayContext != null) {
                _showBroadcastDialog(data);
             }
           });
        }
      }
    });
    
    // 2. Poll Listener
    _firestore.collection('alerts').doc('poll').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['active'] == true) {
             Future.delayed(const Duration(seconds: 4), () {
             if (Get.overlayContext != null) {
                _showPollDialog(data);
             }
           });
        }
      }
    });
  }

  void _showBroadcastDialog(Map<String, dynamic> data) {
    if (Get.isDialogOpen == true) return; // Prevent spamming
    
    // Check if already seen using Hive (Requires Hive Box 'AppPrefs' to be open, handled in main)
    try {
      final box = Hive.box("AppPrefs");
      final lastAlertId = box.get("lastSeenAlertId");
      if (lastAlertId == data['id']) return;

      Get.defaultDialog(
        title: data['title'] ?? "👋 Announcement",
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        content: Column(
          children: [
            if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) 
              Image.network(data['imageUrl'], height: 150, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const SizedBox.shrink()),
            const SizedBox(height: 10),
            Text(data['message'] ?? "", textAlign: TextAlign.center),
          ],
        ),
        textConfirm: "Dismiss",
        confirmTextColor: Colors.white,
        onConfirm: () {
          box.put("lastSeenAlertId", data['id']);
          Get.back();
        },
      );
    } catch (e) {
      // Hive or Get might fail if app closing
    }
  }

  void _showPollDialog(Map<String, dynamic> data) {
    if (Get.isDialogOpen == true) return;

    try {
      final box = Hive.box("AppPrefs");
      final lastPollId = box.get("lastSeenPollId");
      if (lastPollId == data['id']) return;

      Get.defaultDialog(
        title: "🗳️ Live Poll",
        content: Column(
          children: [
            Text(data['question'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            ...(data['options'] as List<dynamic>).asMap().entries.map((entry) {
               return SizedBox(
                 width: double.infinity,
                 child: Padding(
                   padding: const EdgeInsets.only(bottom: 8.0),
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.deepPurple.withValues(alpha: 0.1), 
                       elevation: 0
                     ),
                     onPressed: () {
                       Get.back();
                       Get.snackbar("Voted", "Thanks for voting!");
                       // Here you would optimally push the vote to Firestore
                       box.put("lastSeenPollId", data['id']);
                     },
                     child: Text(entry.value.toString(), style: const TextStyle(color: Colors.deepPurple)),
                   ),
                 ),
               );
            }),
          ],
        ),
        barrierDismissible: true,
      );
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _checkMinVersion(String minVer) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVer = packageInfo.version;
      
      if (_compareVersions(currentVer, minVer) < 0) {
        isForceUpdate.value = true;
        // Override config to show Update Message if not already set by maintenance
        if (!maintenanceConfig.containsKey('title')) {
           maintenanceConfig['title'] = "Update Required";
           maintenanceConfig['message'] = "A new version is available. Please update to continue using the app.";
        }
      } else {
        isForceUpdate.value = false;
      }
    } catch (e) {
      printERROR("Version Check Error: $e");
    }
  }

  int _compareVersions(String v1, String v2) {
    var v1Parts = v1.split('.').map(int.parse).toList();
    var v2Parts = v2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      int p1 = (i < v1Parts.length) ? v1Parts[i] : 0;
      int p2 = (i < v2Parts.length) ? v2Parts[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Sync all local data to Cloud (Manual or Periodic Trigger)
  Future<void> syncAllDataToCloud() async {
    if (_user == null) return;
    printINFO("CloudSync: Starting full sync...");

    try {
      await _syncSettings();
      await _syncHistory();
      await _syncPlaylists();
      await syncFavorites();
      await syncSearchHistory();
      await _syncArtistFavourites();
      await _syncListeningStats();
      
      Get.snackbar(
        "Cloud Sync",
        "Data synced to cloud successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      printERROR("CloudSync Error: $e");
    }
  }

  /// Restore all data from Cloud (Called on Login)
  Future<void> restoreAllDataFromCloud() async {
    if (_user == null) return;
    printINFO("CloudSync: Starting restoration...");

    try {
      await _restoreSettings();
      await _restoreHistory();
      await _restorePlaylists();
      await restoreFavorites();
      await restoreSearchHistory();
      await _restoreArtistFavourites();
      await _restoreListeningStats();

      // Refresh Controllers to reflect changes
      if (Get.isRegistered<SettingsScreenController>()) {
        final settings = Get.find<SettingsScreenController>();
        // Re-init values from Hive
        await settings.reloadFromStorage();
      }
      
      if (Get.isRegistered<ThemeController>()) {
         // Theme might need explicit update if values changed
         final prefs = Hive.box('AppPrefs');
         int? themeType = prefs.get('themeModeType');
         if (themeType != null) {
            Get.find<ThemeController>().changeThemeModeType(ThemeType.values[themeType]);
         }
      }

      if (Get.isRegistered<LibraryPlaylistsController>()) {
        Get.find<LibraryPlaylistsController>().refreshLib();
      }
      
      /*Get.snackbar(
        "Smart Restore",
        "Your data has been restored from the cloud.",
        snackPosition: SnackPosition.BOTTOM,
      );*/
      
    } catch (e) {
      printERROR("CloudSync Restore Error: $e");
    }
  }

  // --- Internal Sync Methods ---

  Future<void> _syncSettings() async {
    final box = Hive.box('AppPrefs');
    final settingsData = {
      'themeModeType': box.get('themeModeType'),
      'themePrimaryColor': box.get('themePrimaryColor'),
      'streamingQuality': box.get('streamingQuality'),
      'noOfHomeScreenContent': box.get('noOfHomeScreenContent'),
      'isTransitionAnimationDisabled': box.get('isTransitionAnimationDisabled'),
      'cacheSongs': box.get('cacheSongs'),
      'skipSilenceEnabled': box.get('skipSilenceEnabled'),
      'loudnessNormalizationEnabled': box.get('loudnessNormalizationEnabled'),
      'autoOpenPlayer': box.get('autoOpenPlayer'),
      'restorePlaybackSession': box.get('restorePlaybackSession',
          defaultValue: box.get('restrorePlaybackSession') ?? false),
      'showVideoOption': box.get('showVideoOption', defaultValue: false),
      'lastSynced': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('settings')
        .set(settingsData, SetOptions(merge: true));
        
    printINFO("CloudSync: Settings synced.");
  }

  Future<void> _restoreSettings() async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('settings')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final box = Hive.box('AppPrefs');
      
      // Update Hive keys if they exist in cloud
      if (data.containsKey('themeModeType')) box.put('themeModeType', data['themeModeType']);
      if (data.containsKey('themePrimaryColor')) box.put('themePrimaryColor', data['themePrimaryColor']);
      if (data.containsKey('streamingQuality')) box.put('streamingQuality', data['streamingQuality']);
      if (data.containsKey('noOfHomeScreenContent')) box.put('noOfHomeScreenContent', data['noOfHomeScreenContent']);
      if (data.containsKey('cacheSongs')) box.put('cacheSongs', data['cacheSongs']);
      if (data.containsKey('restorePlaybackSession')) {
        box.put('restorePlaybackSession', data['restorePlaybackSession']);
        box.put('restrorePlaybackSession', data['restorePlaybackSession']);
      }
      if (data.containsKey('showVideoOption')) {
        box.put('showVideoOption', data['showVideoOption']);
      }
      if (data.containsKey('loudnessNormalizationEnabled')) {
        box.put('loudnessNormalizationEnabled', data['loudnessNormalizationEnabled']);
      }
      if (data.containsKey('autoOpenPlayer')) box.put('autoOpenPlayer', data['autoOpenPlayer']);
      
      printINFO("CloudSync: Settings restored.");
    }
  }

  Future<void> _syncHistory() async {
    // Sync Listening History
    final historyBox = await Hive.openBox('ListeningHistory');
    final historyList = historyBox.values.map((e) => e as Map).toList();
    
    // Store as a massive JSON array or subcollection? 
    // Firestore max doc size 1MB. History can contain many items.
    // For simplicity, let's limit to last 200 items or use a chunked approach.
    // Given the constraints, let's save the last 100 items for now in a single doc.
    
    final recentHistory = historyList
        .take(100)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('history')
        .set({'items': recentHistory}, SetOptions(merge: true));

    printINFO("CloudSync: History synced.");
  }

  Future<void> _restoreHistory() async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('history')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('items')) {
        final List items = data['items'];
        final historyBox = await Hive.openBox('ListeningHistory');
        
        for (var item in items) {
           // Key by songId to prevent duplicates
           if (item is Map && item.containsKey('videoId')) {
             await historyBox.put(item['videoId'], item);
           }
        }
        printINFO("CloudSync: History restored.");
      }
    }
  }

  Future<void> _syncPlaylists() async {
    final libBox = await Hive.openBox("LibraryPlaylists");
    final playlists = libBox.values.map((e) => Playlist.fromJson(e)).toList();
    
    final batch = _firestore.batch();
    final playlistsRef = _firestore.collection('users').doc(_user!.uid).collection('playlists');
    
    for (var pl in playlists) {
       // Ignore downloaded/cached internal playlists if we don't want to sync them?
       // User asked to sync playlists.
       if (pl.playlistId == 'SongsCache' || pl.playlistId == 'SongDownloads') continue;

       final plDoc = playlistsRef.doc(pl.playlistId);
       
       // Sync Metadata
       batch.set(plDoc, {
         'playlistId': pl.playlistId,
         'title': pl.title,
         'description': pl.description,
         'thumbnailUrl': pl.thumbnailUrl,
         'isCloudPlaylist': pl.isCloudPlaylist,
         'isPipedPlaylist': pl.isPipedPlaylist,
         'lastUpdated': FieldValue.serverTimestamp(),
       });
       
       // Sync Songs (Save as a field 'songs' in the playlist doc to verify max size, 
       // but typically playlists are small enough. If large, use subcollection)
       // Let's use a field 'songsData' for simplicity.
       
       final songBox = await Hive.openBox(pl.playlistId);
       final songs = songBox.values.map((e) => e as Map).toList();
       
       // Note: Firestore doc limit 1MB. If playlist > 500 songs, this might fail. 
       // For a simple implementation, this is efficient.
       batch.set(plDoc, {'songsData': songs}, SetOptions(merge: true));
    }
    
    await batch.commit();
    printINFO("CloudSync: Playlists synced.");
  }

  Future<void> _restorePlaylists() async {
    final playlistsRef = _firestore.collection('users').doc(_user!.uid).collection('playlists');
    final snapshot = await playlistsRef.get();
    
    final libBox = await Hive.openBox("LibraryPlaylists");
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final plId = data['playlistId'];
      
      // 1. Restore Metadata
      final pl = Playlist(
        playlistId: plId,
        title: data['title'],
        description: data['description'],
        thumbnailUrl: data['thumbnailUrl'],
        isCloudPlaylist: data['isCloudPlaylist'] ?? false,
        isPipedPlaylist: data['isPipedPlaylist'] ?? false,
      );
      
      await libBox.put(plId, pl.toJson());
      
      // 2. Restore Songs
      if (data.containsKey('songsData')) {
        final List songs = data['songsData'];
        final songBox = await Hive.openBox(plId);
        await songBox.clear(); // Overwrite with cloud version to ensure sync
        for (int i = 0; i < songs.length; i++) {
          await songBox.add(songs[i]);
        }
      }
    }
    printINFO("CloudSync: Playlists restored.");
  }

  // --- Favorites & Search History Sync ---

  Future<void> syncFavorites() async {
    final box = await Hive.openBox('LIBFAV');
    final favoritesList = box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('favorites')
        .set({'items': favoritesList}, SetOptions(merge: true));

    printINFO("CloudSync: Favorites synced.");
  }

  Future<void> restoreFavorites() async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('favorites')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('items')) {
        final List items = data['items'];
        final box = await Hive.openBox('LIBFAV');
        
        for (var item in items) {
           if (item is Map && item.containsKey('videoId')) {
             await box.put(item['videoId'], item);
           }
        }
        printINFO("CloudSync: Favorites restored.");
      }
    }
  }

  Future<void> syncSearchHistory() async {
    final queryBox = await Hive.openBox("searchQuery");
    final queries = queryBox.values.map((e) => e.toString()).toList();
    
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('search_history')
        .set({'queries': queries}, SetOptions(merge: true));

    printINFO("CloudSync: Search History synced.");
  }

  Future<void> restoreSearchHistory() async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('search_history')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('queries')) {
        final List queries = data['queries'];
        final queryBox = await Hive.openBox('searchQuery');
        
        await queryBox.clear(); 
        for (var query in queries) {
             await queryBox.add(query);
        }
        printINFO("CloudSync: Search History restored.");
      }
    }
  }

  Future<void> syncHistory() async {
    if (_user != null) await _syncHistory();
  }

  Future<void> syncArtistFavourites() async {
    if (_user != null) await _syncArtistFavourites();
  }

  Future<void> syncListeningStats() async {
    if (_user != null) await _syncListeningStats();
  }

  Future<void> _syncArtistFavourites() async {
    final box = await Hive.openBox('LibraryArtists');
    final artists = box.values
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('artist_favourites')
        .set({'items': artists}, SetOptions(merge: true));
  }

  Future<void> _restoreArtistFavourites() async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('data')
        .doc('artist_favourites')
        .get();
    final items = doc.data()?['items'];
    if (items is! List) return;

    final box = await Hive.openBox('LibraryArtists');
    for (final item in items) {
      if (item is Map && item['browseId'] != null) {
        await box.put(item['browseId'].toString(), Map<String, dynamic>.from(item));
      }
    }
  }

  Future<void> _syncListeningStats() async {
    final box = await Hive.openBox<ListeningStatDay>('ListeningStats');
    final statsRef = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('listening_stats');
    final batch = _firestore.batch();
    final metadata = Get.isRegistered<ListeningStatsService>() &&
            Get.find<ListeningStatsService>().isInitialized
        ? Get.find<ListeningStatsService>().getAllSongMetadata()
        : <String, Map<String, String>>{};
    for (final stat in box.values) {
      final statMetadata = <String, Map<String, String>>{
        for (final songId in stat.songStats.keys)
          if (metadata.containsKey(songId)) songId: metadata[songId]!,
      };
      batch.set(statsRef.doc(stat.date), {
        'date': stat.date,
        'totalSeconds': stat.totalSeconds,
        'songStats': stat.songStats,
        'songMetadata': statMetadata,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> _restoreListeningStats() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('listening_stats')
        .get();
    if (snapshot.docs.isEmpty) return;

    final box = await Hive.openBox<ListeningStatDay>('ListeningStats');
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawStats = data['songStats'];
      final songStats = <String, int>{};
      if (rawStats is Map) {
        rawStats.forEach((key, value) {
          final seconds = value is num ? value.toInt() : int.tryParse('$value');
          if (seconds != null) songStats[key.toString()] = seconds;
        });
      }
      final rawMetadata = data['songMetadata'];
      final songMetadata = <String, Map<String, String>>{};
      if (rawMetadata is Map) {
        rawMetadata.forEach((songId, value) {
          if (value is Map) {
            songMetadata[songId.toString()] = value.map(
              (key, metadataValue) =>
                  MapEntry(key.toString(), metadataValue.toString()),
            );
          }
        });
      }
      final date = data['date']?.toString() ?? doc.id;
      await box.put(
        date,
        ListeningStatDay(
          date: date,
          totalSeconds: (data['totalSeconds'] as num?)?.toInt() ?? 0,
          songStats: songStats,
        ),
      );
      if (songMetadata.isNotEmpty &&
          Get.isRegistered<ListeningStatsService>() &&
          Get.find<ListeningStatsService>().isInitialized) {
        await Get.find<ListeningStatsService>()
            .restoreSongMetadata(songMetadata);
      }
    }
  }
}

