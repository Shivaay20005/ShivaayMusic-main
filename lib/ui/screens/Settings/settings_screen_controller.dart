import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shivaaymusic/services/permission_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/update_check_flag_file.dart';
import '/services/piped_service.dart';
import '/services/privacy_service.dart';
import '../Library/library_controller.dart';
import '../../widgets/snackbar.dart';
import '../../../utils/helper.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '../Home/home_screen_controller.dart';
import 'package:shivaaymusic/ui/utils/theme_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsScreenController extends GetxController {
  String _supportDir = "";
  final cacheSongs = false.obs;
  final setBox = Hive.box("AppPrefs");
  final themeModetype = ThemeType.dynamic.obs;
  final skipSilenceEnabled = false.obs;
  final loudnessNormalizationEnabled = false.obs;
  final noOfHomeScreenContent = 11.obs;
  final streamingQuality = AudioQuality.High.obs;
  final playerUi = 0.obs;
  final slidableActionEnabled = true.obs;
  final isIgnoringBatteryOptimizations = false.obs;
  final autoOpenPlayer = false.obs;
  final discoverContentType = "BOLI".obs;
  final isNewVersionAvailable = false.obs;
  final isLinkedWithPiped = false.obs;
  final stopPlyabackOnSwipeAway = false.obs;
  final currentAppLanguageCode = "en".obs;
  final downloadLocationPath = "".obs;
  final exportLocationPath = "".obs;
  final downloadingFormat = "".obs;
  final autoDownloadFavoriteSongEnabled = false.obs;
  final isTransitionAnimationDisabled = false.obs;
  final isBottomNavBarEnabled = false.obs;
  final backgroundPlayEnabled = true.obs;
  final keepScreenAwake = false.obs;
  final restorePlaybackSession = false.obs;
  final showVideoOption = false.obs;
  final cacheHomeScreenData = true.obs;
  final isSmartPrefetchEnabled = false.obs;
  final cacheSize = "0 MB".obs;
  Timer? _cacheTimer;
  // Get version dynamically from package info (from pubspec.yaml)
  final currentVersion = "V1.0.6".obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize asynchronously without blocking UI
    _initializeSettings();
  }

  void _initializeSettings() {
    // Run initialization in background without blocking UI
    Future.microtask(() async {
      try {
        // Must create directory first to initialize _supportDir
        await _createInAppSongDownDir();
        await _setInitValue();
        await _loadAppVersion();
        if (updateCheckFlag) _checkNewVersion();
      } catch (e) {
        printERROR('Settings initialization error: $e');
      }
    });
  }

  Future<void> reloadFromStorage() => _setInitValue();

  get currentVision => currentVersion.value;
  get isCurrentPathsupportDownDir {
    if (_supportDir.isEmpty) return false;
    return "$_supportDir/Music" == downloadLocationPath.value;
  }
  String get supportDirPath => _supportDir;

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = "V${packageInfo.version}";
    } catch (e) {
      // Fallback to default version if package info fails
      currentVersion.value = "V1.0.6";
    }
  }

  _checkNewVersion() {
    newVersionCheck(currentVersion.value)
        .then((value) => isNewVersionAvailable.value = value);
  }

  Future<String> _createInAppSongDownDir() async {
    _supportDir = (await getApplicationSupportDirectory()).path;
    final directory = Directory("$_supportDir/Music/");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return "$_supportDir/Music";
  }

  Future<void> _setInitValue() async {
    final isDesktop = GetPlatform.isDesktop;
    final appLang = setBox.get('currentAppLanguageCode') ?? "en";
    currentAppLanguageCode.value = appLang == "zh_Hant"
        ? "zh-TW"
        : appLang == "zh_Hans"
            ? "zh-CN"
            : appLang;
    // Make Bottom Navigation enabled by default on Android and iOS
    isBottomNavBarEnabled.value =
        isDesktop ? false : (setBox.get("isBottomNavBarEnabled") ?? true);
    noOfHomeScreenContent.value = setBox.get("noOfHomeScreenContent") ?? 11;
    isTransitionAnimationDisabled.value =
        setBox.get("isTransitionAnimationDisabled") ?? false;
    cacheSongs.value = setBox.get('cacheSongs') ?? false;
    themeModetype.value = ThemeType.values[setBox.get('themeModeType') ?? 0];
    skipSilenceEnabled.value =
        isDesktop ? false : (setBox.get("skipSilenceEnabled") ?? false);
    loudnessNormalizationEnabled.value = isDesktop
        ? false
        : (setBox.get("loudnessNormalizationEnabled") ?? false);
    autoOpenPlayer.value = (setBox.get("autoOpenPlayer") ?? true);
    restorePlaybackSession.value =
        setBox.get("restorePlaybackSession", defaultValue:
            setBox.get("restrorePlaybackSession") ?? false);
    showVideoOption.value = setBox.get("showVideoOption") ?? false;
    cacheHomeScreenData.value = setBox.get("cacheHomeScreenData") ?? true;
    streamingQuality.value =
        AudioQuality.values[setBox.get('streamingQuality') ?? AudioQuality.High.index];
    playerUi.value = isDesktop ? 0 : (setBox.get('playerUi') ?? 0);
    backgroundPlayEnabled.value = setBox.get("backgroundPlayEnabled") ?? true;
    keepScreenAwake.value =
        setBox.get("keepScreenAwake") ?? (GetPlatform.isDesktop ? true : false);
    
    // Now _supportDir is guaranteed to be initialized
    final defaultDownloadPath = "$_supportDir/Music";
    final downloadPath = setBox.get('downloadLocationPath') ?? defaultDownloadPath;
    downloadLocationPath.value =
        (isDesktop && downloadPath.contains("emulated"))
            ? defaultDownloadPath
            : downloadPath;

    exportLocationPath.value =
        setBox.get("exportLocationPath") ?? "/storage/emulated/0/Music";
    downloadingFormat.value = setBox.get('downloadingFormat') ?? "m4a";
    discoverContentType.value = setBox.get('discoverContentType') ?? "BOLI";
    slidableActionEnabled.value = setBox.get('slidableActionEnabled') ?? true;
    if (setBox.containsKey("piped")) {
      final pipedData = setBox.get("piped");
      if (pipedData != null && pipedData is Map) {
        isLinkedWithPiped.value = pipedData['isLoggedIn'] ?? false;
      }
    }
    stopPlyabackOnSwipeAway.value =
        setBox.get('stopPlyabackOnSwipeAway') ?? false;
    if (GetPlatform.isAndroid) {
      isIgnoringBatteryOptimizations.value =
          (await Permission.ignoreBatteryOptimizations.isGranted);
    }
    autoDownloadFavoriteSongEnabled.value =
        setBox.get("autoDownloadFavoriteSongEnabled") ?? false;
    isSmartPrefetchEnabled.value = setBox.get("isSmartPrefetchEnabled") ?? false;
    updateCacheSize();
    _startCacheTimer();
  }

  void _startCacheTimer() {
    _cacheTimer?.cancel();
    _cacheTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      updateCacheSize();
    });
  }

  @override
  void onClose() {
    _cacheTimer?.cancel();
    super.onClose();
  }

  void setAppLanguage(String? val) {
    Get.updateLocale(Locale(val!));
    Get.find<MusicServices>().hlCode = val;
    Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
    currentAppLanguageCode.value = val;
    setBox.put('currentAppLanguageCode', val);
  }

  void setContentNumber(int? no) {
    noOfHomeScreenContent.value = no!;
    setBox.put("noOfHomeScreenContent", no);
  }

  void setStreamingQuality(dynamic val) {
    setBox.put("streamingQuality", AudioQuality.values.indexOf(val));
    streamingQuality.value = val;
  }

  void setPlayerUi(dynamic val) {
    final playerCon = Get.find<PlayerController>();
    setBox.put("playerUi", val);
    if (val == 1 && playerCon.gesturePlayerStateAnimationController == null) {
      playerCon.initGesturePlayerStateAnimationController();
    }

    playerUi.value = val;
  }

  void enableBottomNavBar(bool val) {
    final homeScrCon = Get.find<HomeScreenController>();
    final playerCon = Get.find<PlayerController>();
    if (val) {
      homeScrCon.onSideBarTabSelected(3);
      isBottomNavBarEnabled.value = true;
    } else {
      isBottomNavBarEnabled.value = false;
      homeScrCon.onSideBarTabSelected(5);
    }
    if (!Get.find<PlayerController>().initFlagForPlayer) {
      playerCon.playerPanelMinHeight.value =
          val ? 75.0 + 86.0 + Get.mediaQuery.viewPadding.bottom : 75.0 + Get.mediaQuery.viewPadding.bottom;
    }
    setBox.put("isBottomNavBarEnabled", val);
  }

  void toggleSlidableAction(bool val) {
    setBox.put("slidableActionEnabled", val);
    slidableActionEnabled.value = val;
  }

  void changeDownloadingFormat(String? val) {
    setBox.put("downloadingFormat", val);
    downloadingFormat.value = val!;
  }

  Future<void> setExportedLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select export file folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    setBox.put("exportLocationPath", pickedFolderPath);
    exportLocationPath.value = pickedFolderPath;
  }

  Future<void> setDownloadLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select downloads folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    setBox.put("downloadLocationPath", pickedFolderPath);
    downloadLocationPath.value = pickedFolderPath;
  }

  void disableTransitionAnimation(bool val) {
    setBox.put('isTransitionAnimationDisabled', val);
    isTransitionAnimationDisabled.value = val;
  }

  Future<void> clearImagesCache() async {
    final tempImgDirPath =
        "${(await getApplicationCacheDirectory()).path}/libCachedImageData";
    final tempImgDir = Directory(tempImgDirPath);
    try {
      if (await tempImgDir.exists()) {
        await tempImgDir.delete(recursive: true);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void resetDownloadLocation() {
    final defaultPath = "$_supportDir/Music";
    setBox.put("downloadLocationPath", defaultPath);
    downloadLocationPath.value = defaultPath;
  }

  void onThemeChange(dynamic val) {
    setBox.put('themeModeType', ThemeType.values.indexOf(val));
    themeModetype.value = val;
    Get.find<ThemeController>().changeThemeModeType(val);
  }

  void onContentChange(dynamic value) {
    setBox.put('discoverContentType', value);
    discoverContentType.value = value;
    Get.find<HomeScreenController>().changeDiscoverContent(value);
  }

  void toggleCachingSongsValue(bool value) {
    setBox.put("cacheSongs", value);
    cacheSongs.value = value;
  }

  void toggleSkipSilence(bool val) {
    Get.find<PlayerController>().toggleSkipSilence(val);
    setBox.put('skipSilenceEnabled', val);
    skipSilenceEnabled.value = val;
  }

  void toggleLoudnessNormalization(bool val) {
    Get.find<PlayerController>().toggleLoudnessNormalization(val);
    setBox.put("loudnessNormalizationEnabled", val);
    loudnessNormalizationEnabled.value = val;
  }

  void toggleRestorePlaybackSession(bool val) {
    setBox.put("restorePlaybackSession", val);
    // Keep the legacy key for one release so older sessions still migrate cleanly.
    setBox.put("restrorePlaybackSession", val);
    restorePlaybackSession.value = val;
  }

  void toggleShowVideoOption(bool val) {
    setBox.put("showVideoOption", val);
    showVideoOption.value = val;
    if (!val && Get.isRegistered<PlayerController>()) {
      Get.find<PlayerController>().disableVideoMode();
    }
  }

  Future<void> toggleCacheHomeScreenData(bool val) async {
    setBox.put("cacheHomeScreenData", val);
    cacheHomeScreenData.value = val;
    if (!val) {
      Hive.openBox("homeScreenData").then((box) async {
        await box.clear();
        await box.close();
      });
    } else {
      await Hive.openBox("homeScreenData");
      Get.find<HomeScreenController>().cachedHomeScreenData(updateAll: true);
    }
  }

  void toggleAutoDownloadFavoriteSong(bool val) {
    setBox.put("autoDownloadFavoriteSongEnabled", val);
    autoDownloadFavoriteSongEnabled.value = val;
  }

  void toggleSmartPrefetch(bool val) {
    setBox.put("isSmartPrefetchEnabled", val);
    isSmartPrefetchEnabled.value = val;
  }

  Future<void> updateCacheSize() async {
    try {
      final cacheDir = (await getTemporaryDirectory()).path;
      final dir = Directory("$cacheDir/cachedSongs/");
      if (await dir.exists()) {
        int totalSize = 0;
        await for (var file in dir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        cacheSize.value = "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
      } else {
        cacheSize.value = "0 MB";
      }
    } catch (e) {
      cacheSize.value = "Unknown";
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = (await getTemporaryDirectory()).path;
      final dir = Directory("$cacheDir/cachedSongs/");
      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync(recursive: true);
        for (final file in files) {
          try {
            if (file is File) await file.delete();
          } catch (e) {
            // Skip files that are currently in use by the player
            printINFO("Skipping file in use: ${file.path}");
          }
        }
        updateCacheSize();
      }
    } catch (e) {
      printERROR("Error clearing cache: $e");
    }
  }

  void toggleBackgroundPlay(bool val) {
    setBox.put('backgroundPlayEnabled', val);
    backgroundPlayEnabled.value = val;
  }

  void toggleKeepScreenAwake(bool val) {
    setBox.put('keepScreenAwake', val);
    keepScreenAwake.value = val;
    try {
        if (val) {
          // enable wakelock immediately if music is playing
          if (Get.find<PlayerController>().buttonState.value ==
              PlayButtonState.playing) {
            WakelockPlus.enable();
          }
        } else {
          WakelockPlus.disable();
        }
     
    } catch (e) {
      // ignore if player/controller not available
    }
  }

  Future<void> enableIgnoringBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
    isIgnoringBatteryOptimizations.value =
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  void toggleAutoOpenPlayer(bool val) {
    setBox.put('autoOpenPlayer', val);
    autoOpenPlayer.value = val;
  }

  Future<void> unlinkPiped() async {
    Get.find<PipedServices>().logout();
    isLinkedWithPiped.value = false;
    Get.find<LibraryPlaylistsController>().removePipedPlaylists();
    final box = await Hive.openBox('blacklistedPlaylist');
    box.clear();
    ScaffoldMessenger.of(Get.context!).showSnackBar(
        snackbar(Get.context!, "unlinkAlert".tr, size: SanckBarSize.MEDIUM));
    box.close();
  }

  Future<void> resetAppSettingsToDefault() async {
    // 1. Clear Hive Database
    await setBox.clear();

    // 2. Reset Memory Variables to Defaults
    cacheSongs.value = false;
    themeModetype.value = ThemeType.dynamic;
    skipSilenceEnabled.value = false;
    loudnessNormalizationEnabled.value = false;
    noOfHomeScreenContent.value = 11;
    streamingQuality.value = AudioQuality.High;
    playerUi.value = GetPlatform.isDesktop ? 0 : 0;
    slidableActionEnabled.value = true;
    autoOpenPlayer.value = false;
    discoverContentType.value = "BOLI";
    stopPlyabackOnSwipeAway.value = false;
    currentAppLanguageCode.value = "en";
    downloadingFormat.value = "m4a";
    autoDownloadFavoriteSongEnabled.value = false;
    isTransitionAnimationDisabled.value = false;
    isBottomNavBarEnabled.value = GetPlatform.isDesktop ? false : true;
    backgroundPlayEnabled.value = true;
    keepScreenAwake.value = GetPlatform.isDesktop ? true : false;
    restorePlaybackSession.value = false;
    showVideoOption.value = false;
    setBox.put("showVideoOption", false);
    cacheHomeScreenData.value = true;
    isSmartPrefetchEnabled.value = false;

    // 3. Reset Privacy Service State
    if (Get.isRegistered<PrivacyService>()) {
      final privacyService = Get.find<PrivacyService>();
      privacyService.isAppLockEnabled.value = false;
      privacyService.isIncognitoMode.value = false;
      // Also clear privacy hive keys if they were stored in separate box, 
      // but PrivacyService uses 'AppPrefs' which we just cleared above.
    }

    // 4. Apply Side Effects
    Get.updateLocale(const Locale('en'));
    Get.find<ThemeController>().changeThemeModeType(ThemeType.dynamic);
    
    // 5. Reset download path
    resetDownloadLocation();
  }

  void toggleStopPlyabackOnSwipeAway(bool val) {
    setBox.put('stopPlyabackOnSwipeAway', val);
    stopPlyabackOnSwipeAway.value = val;
  }

  Future<void> closeAllDatabases() async {
    await Hive.close();
  }

  Future<String> get dbDir async {
    if (GetPlatform.isDesktop) {
      return "$supportDirPath/db";
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  // ============================================
  // 🔐 Privacy & Security Methods
  // ============================================

  /// Toggle App Lock (Biometric/PIN)
  Future<void> toggleAppLock(bool value) async {
    try {
      if (Get.isRegistered<PrivacyService>()) {
        await Get.find<PrivacyService>().toggleAppLock(value);
      } else {
        printERROR('PrivacyService not initialized');
      }
    } catch (e) {
      printERROR('Error toggling app lock: $e');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        snackbar(Get.context!, 'Error enabling app lock', size: SanckBarSize.MEDIUM),
      );
    }
  }

  /// Toggle Incognito Mode
  Future<void> toggleIncognitoMode(bool value) async {
    try {
      if (Get.isRegistered<PrivacyService>()) {
        await Get.find<PrivacyService>().toggleIncognitoMode(value);
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          snackbar(
            Get.context!,
            value ? 'Incognito mode enabled' : 'Incognito mode disabled',
            size: SanckBarSize.MEDIUM,
          ),
        );
      } else {
        printERROR('PrivacyService not initialized');
      }
    } catch (e) {
      printERROR('Error toggling incognito mode: $e');
    }
  }

  /// Clear Listening History
  Future<void> clearListeningHistory() async {
    try {
      if (Get.isRegistered<PrivacyService>()) {
        await Get.find<PrivacyService>().clearListeningHistory();
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          snackbar(Get.context!, 'Listening history cleared', size: SanckBarSize.MEDIUM),
        );
      } else {
        printERROR('PrivacyService not initialized');
      }
    } catch (e) {
      printERROR('Error clearing history: $e');
    }
  }

  /// Clear All History (Listening + Search)
  Future<void> clearAllHistory() async {
    try {
      if (Get.isRegistered<PrivacyService>()) {
        await Get.find<PrivacyService>().clearAllHistory();
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          snackbar(Get.context!, 'All history cleared', size: SanckBarSize.MEDIUM),
        );
      } else {
        printERROR('PrivacyService not initialized');
      }
    } catch (e) {
      printERROR('Error clearing all history: $e');
    }
  }
}
