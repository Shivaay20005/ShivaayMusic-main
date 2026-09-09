import 'package:firebase_core/firebase_core.dart';
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
import '/services/audio_booster_controller.dart';
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

final ValueNotifier<String> _startupStatus =
    ValueNotifier<String>('Preparing your music space…');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (GetPlatform.isDesktop) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.maximize();
    });
  }

  // Render a Flutter frame before initializing plugins. Android can otherwise
  // look permanently frozen on its native splash while a plugin is starting.
  runApp(_StartupApp(status: _startupStatus));
  await Future<void>.delayed(const Duration(milliseconds: 50));

  try {
    _startupStatus.value = 'Connecting securely…';
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Firebase/network issues must never prevent offline app startup.
    }

    _startupStatus.value = 'Loading your library…';
    await initHive().timeout(const Duration(seconds: 15));
    _setAppInitPrefs();

    _startupStatus.value = 'Starting app services…';
    await startApplicationServices();
    Get.put(AuthService(), permanent: true);

    // Register HomeWidget Background Callback
    /*if (!GetPlatform.isDesktop && GetPlatform.isAndroid) {
      HomeWidget.registerInteractivityCallback(backgroundCallback);
    }*/

    _startupStatus.value = 'Starting the music player…';
    final audioHandler =
        await initAudioService().timeout(const Duration(seconds: 30));
    Get.put<AudioHandler>(audioHandler, permanent: true);

    WidgetsBinding.instance.addObserver(LifecycleHandler());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    try {
      TerminateRestart.instance.initialize();
    } catch (e) {
      debugPrint('Restart service initialization error: $e');
    }
    runApp(const MyApp());
  } catch (error, stackTrace) {
    debugPrint('Fatal startup error: $error\n$stackTrace');
    runApp(_StartupFailureApp(error: error.toString()));
  }
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

class _StartupApp extends StatelessWidget {
  const _StartupApp({required this.status});

  final ValueListenable<String> status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09070D),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (context, message, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icons/imagelogo.png',
                        width: 104,
                        height: 104,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ShivaayMusic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        color: Color(0xFFB98AFF),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09070D),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF8A80),
                    size: 58,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ShivaayMusic could not start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please take a screenshot of the message below. Your data has not been deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFCCBC),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/imagelogo.png', width: 92, height: 92),
            const SizedBox(height: 22),
            CircularProgressIndicator(color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'Setting up your music space…',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
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
            return const _AuthLoadingScreen();
          }
          return authService.currentUser != null
              ? const Home()
              : const LoginScreen();
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
  Get.lazyPut(() => AudioBoosterController(), fenix: true);

  // Stats are initialized in the background so a damaged/legacy analytics box
  // can never hold the app on the native splash screen.
  final statsService = ListeningStatsService();
  Get.put(statsService, permanent: true);
  statsService.init().catchError((Object error, StackTrace stackTrace) {
    debugPrint('Listening stats initialization error: $error');
    return statsService;
  });
  
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
