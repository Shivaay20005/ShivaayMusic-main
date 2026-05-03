import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_service/audio_service.dart';
// import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terminate_restart/terminate_restart.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart'; // Import created options

import 'package:shivaaymusic/ui/screens/Search/search_screen_controller.dart';
import 'package:shivaaymusic/utils/get_localization.dart';
import '/services/downloader.dart';
import '/services/piped_service.dart';
import '/services/privacy_service.dart';
import '/services/auth_service.dart';
import '/services/cloud_service.dart';
import '/services/music_room_service.dart';
import '/services/room_chat_service.dart';
import '/services/listening_stats_service.dart';
import 'utils/app_link_controller.dart';
import '/services/audio_handler.dart';
import '/services/music_service.dart';
import '/ui/home.dart';
import '/ui/screens/Auth/login_screen.dart';
import '/ui/player/player_controller.dart';
import 'ui/screens/Settings/settings_screen_controller.dart';
import 'package:shivaaymusic/ui/utils/theme_controller.dart';
import 'ui/screens/Home/home_screen_controller.dart';
import 'ui/screens/MusicRoom/music_room_controller.dart';
import 'ui/screens/Library/library_controller.dart';
import 'utils/system_tray.dart';
import 'ui/widgets/maintenance_overlay.dart';
import 'utils/update_check_flag_file.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (GetPlatform.isDesktop) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.maximize();
    });
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - app can still work without Firebase
  }

  await initHive();
  _setAppInitPrefs();
  startApplicationServices();
  Get.put(AuthService(), permanent: true);
  
  // Register HomeWidget Background Callback
  /*if (!GetPlatform.isDesktop && GetPlatform.isAndroid) {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }*/
  
  Get.put<AudioHandler>(await initAudioService(), permanent: true);
  WidgetsBinding.instance.addObserver(LifecycleHandler());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  TerminateRestart.instance.initialize();
  runApp(const MyApp());
}


// Basic Background callback for HomeWidget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  /*if (uri?.host == 'playpause') {
    final audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.shivaay20005.shivaaymusicflutter',
        androidNotificationChannelName: 'ShivaayMusic',
        androidNotificationOngoing: true,
      ),
    );
    final playing = audioHandler.playbackState.value.playing;
    if (playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  } else if (uri?.host == 'next') {
    final audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.shivaay20005.shivaaymusicflutter',
        androidNotificationChannelName: 'ShivaayMusic',
        androidNotificationOngoing: true,
      ),
    );
    await audioHandler.skipToNext();
  } else if (uri?.host == 'prev') {
    final audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.shivaay20005.shivaaymusicflutter',
        androidNotificationChannelName: 'ShivaayMusic',
        androidNotificationOngoing: true,
      ),
    );
    await audioHandler.skipToPrevious();
  }*/
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (!GetPlatform.isDesktop) Get.put(AppLinksController());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Use startup-registered AuthService singleton
    final authService = Get.find<AuthService>();
    
    return GetMaterialApp(
        title: 'ShivaayMusic',
        home: Obx(() {
          if (authService.isInitializing.value) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     CircularProgressIndicator(),
                     SizedBox(height: 20),
                     Text("Setting up your music space..."),
                  ],
                ),
              ),
            );
          }
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            initialData: FirebaseAuth.instance.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data ?? authService.currentUser;
              return user != null ? const Home() : const LoginScreen();
            },
          );
        }),
        debugShowCheckedModeBanner: false,
        translations: Languages(),
        locale:
            Locale(Hive.box("AppPrefs").get('currentAppLanguageCode') ?? "en"),
        fallbackLocale: const Locale("en"),
        builder: (context, child) {
          final mQuery = MediaQuery.of(context);
          final scale =
              mQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1);
          return Stack(
            children: [
              GetX<ThemeController>(
                builder: (controller) => MediaQuery(
                  data: mQuery.copyWith(textScaler: scale),
                  child: AnimatedTheme(
                      duration: const Duration(milliseconds: 700),
                      data: controller.themedata.value!,
                      child: child!),
                ),
              ),
              GestureDetector(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.transparent,
                    height: mQuery.padding.bottom,
                    width: mQuery.size.width,
                  ),
                ),
              ),
              
              // 🔒 GLOBAL LOCK SCREEN OVERLAY
              Obx(() {
                if (Get.isRegistered<PrivacyService>() && 
                    Get.find<PrivacyService>().isLocked.value) {
                  return Material(
                    color: Colors.black.withValues(alpha: 0.95), // High opacity overlay
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/icons/icon.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "ShivaayMusic Locked",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Authenticate to continue",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.find<PrivacyService>().verifyAppLock();
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text("Unlock"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              
               // 🚧 GLOBAL MAINTENANCE OVERLAY
               Obx(() {
                 if (Get.isRegistered<CloudService>() && Get.isRegistered<AuthService>()) {
                    final cloudService = Get.find<CloudService>();
                    final authService = Get.find<AuthService>();
                    
                    // Bypass maintenance/force-update if user is Admin
                    if (authService.isAdmin.value) {
                      return const SizedBox.shrink();
                    }

                    // Show Overlay if Maintenance OR Force Update
                    if (cloudService.isMaintenanceMode.value || cloudService.isForceUpdate.value) {
                      return MaintenanceOverlay(config: cloudService.maintenanceConfig);
                    }
                 }
                 return const SizedBox.shrink();
               }),

            ],
          );
        });
  }
}

Future<void> startApplicationServices() async {
  Get.lazyPut(() => PipedServices(), fenix: true);
  Get.lazyPut(() => MusicServices(), fenix: true);
  Get.lazyPut(() => ThemeController(), fenix: true);
  Get.lazyPut(() => PlayerController(), fenix: true);
  Get.lazyPut(() => HomeScreenController(), fenix: true);
  Get.lazyPut(() => LibrarySongsController(), fenix: true);
  Get.lazyPut(() => LibraryPlaylistsController(), fenix: true);
  Get.lazyPut(() => LibraryAlbumsController(), fenix: true);
  Get.lazyPut(() => LibraryArtistsController(), fenix: true);
  Get.lazyPut(() => SettingsScreenController(), fenix: true);
  Get.lazyPut(() => Downloader(), fenix: true);

  // Listening Stats Service
  final statsService = ListeningStatsService();
  Get.put(statsService);
  statsService.init(); // Run asynchronously without blocking
  
  // Privacy Service
  Get.put(PrivacyService(), permanent: true);
  
  // Music Room Services - Real-time collaborative listening
  Get.put(MusicRoomService(), permanent: true);
  Get.put(RoomChatService(), permanent: true);
  Get.put(SearchScreenController(), permanent: true);
  Get.put(MusicRoomController(), permanent: true);
  
  if (GetPlatform.isDesktop) {
    Get.put(DesktopSystemTray());
  }
}

initHive() async {
  String applicationDataDirectoryPath;
  if (GetPlatform.isDesktop) {
    applicationDataDirectoryPath =
        "${(await getApplicationSupportDirectory()).path}/db";
  } else {
    applicationDataDirectoryPath =
        (await getApplicationDocumentsDirectory()).path;
  }
  await Hive.initFlutter(applicationDataDirectoryPath);
  await Hive.openBox("SongsCache");
  await Hive.openBox("SongDownloads");
  await Hive.openBox('SongsUrlCache');
  await Hive.openBox("AppPrefs");
}

void _setAppInitPrefs() {
  final appPrefs = Hive.box("AppPrefs");
  if (appPrefs.isEmpty) {
    appPrefs.putAll({
      'themeModeType': 0,
      "cacheSongs": false,
      "skipSilenceEnabled": false,
      'streamingQuality': 1,
      'themePrimaryColor': 4278199603,
      'discoverContentType': "BOLI",
      'newVersionVisibility': updateCheckFlag,
      "cacheHomeScreenData": true
    });
  }
}

class LifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      // Check App Lock on Resume
      if (Get.isRegistered<PrivacyService>()) {
        final privacyService = Get.find<PrivacyService>();
        // Only lock if we are NOT currently authenticating
        // This prevents the loop where returning from Auth immediately re-locks
        if (privacyService.shouldShowAppLock() && !privacyService.isAuthenticating.value) {
           // Small delay to ensure UI is ready
           Future.delayed(const Duration(milliseconds: 100), () {
             privacyService.lockApp(); // Just show overlay, don't prompt yet
           });
        }
      }
    } else if (state == AppLifecycleState.detached) {
      await Get.find<AudioHandler>().customAction("saveSession");
    }
  }
}
