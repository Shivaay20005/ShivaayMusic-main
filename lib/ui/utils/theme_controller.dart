import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'dart:async';
import 'package:hive/hive.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shivaaymusic/utils/helper.dart';

class ThemeController extends GetxController {
  final primaryColor = Colors.deepPurple[400].obs;
  final textColor = Colors.white24.obs;
  final themedata = Rxn<ThemeData>();

  /// The method channel for setting the title bar color on Windows.
  final platform = const MethodChannel('win_titlebar_color');
  String? currentSongId;
  late Brightness systemBrightness;

  Timer? _timer;

  ThemeController() {
    systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    primaryColor.value =
        Color(Hive.box('appPrefs').get("themePrimaryColor") ?? 4278199603);

    changeThemeModeType(
        ThemeType.values[Hive.box('appPrefs').get("themeModeType") ?? 0]);

    _listenSystemBrightness();

    if (ThemeType.values[Hive.box('appPrefs').get("themeModeType") ?? 0] == ThemeType.automatic) {
      _startAutomaticThemeTimer();
    }

    super.onInit();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startAutomaticThemeTimer() {
    _timer?.cancel();
    // Check every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (Hive.box('appPrefs').get("themeModeType") == ThemeType.values.indexOf(ThemeType.automatic)) {
        changeThemeModeType(ThemeType.automatic, sysCall: true);
      } else {
        timer.cancel();
      }
    });
  }

  bool _isDayTime() {
    final now = DateTime.now();
    return now.hour >= 6 && now.hour < 18;
  }

  void _listenSystemBrightness() {
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    platformDispatcher.onPlatformBrightnessChanged = () {
      systemBrightness = platformDispatcher.platformBrightness;
      changeThemeModeType(
          ThemeType.values[Hive.box('appPrefs').get("themeModeType")],
          sysCall: true);
    };
  }

  void changeThemeModeType(dynamic value, {bool sysCall = false}) {
    _timer?.cancel(); // Cancel any existing timer to avoid duplicates

    if (value == ThemeType.system) {
      themedata.value = _createThemeData(
          null,
          systemBrightness == Brightness.light
              ? ThemeType.light
              : ThemeType.dark);
    } else if (value == ThemeType.automatic) {
        _startAutomaticThemeTimer();
        themedata.value = _createThemeData(
          null,
          _isDayTime() ? ThemeType.light : ThemeType.dark);
    } else {
      if (sysCall) return;
      themedata.value = _createThemeData(
          value == ThemeType.dynamic
              ? _createMaterialColor(primaryColor.value!)
              : null,
          value);
    }
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  void setTheme(ImageProvider imageProvider, String songId) async {
    if (songId == currentSongId) return;
    PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(imageProvider, height: 200, width: 200));
    //final colorList = generator.colors;
    final paletteColor = generator.dominantColor ??
        generator.darkMutedColor ??
        generator.darkVibrantColor ??
        generator.lightMutedColor ??
        generator.lightVibrantColor;
    primaryColor.value = paletteColor!.color;
    textColor.value = paletteColor.bodyTextColor;
    // printINFO(paletteColor.color.computeLuminance().toString());0.11 ref
    if (paletteColor.color.computeLuminance() > 0.10) {
      primaryColor.value = paletteColor.color.withLightness(0.10);
      textColor.value = Colors.white.withValues(alpha: 0.9); // Increased contrast (white90 equivalent)
    }
    final primarySwatch = _createMaterialColor(primaryColor.value!);
    themedata.value = _createThemeData(primarySwatch, ThemeType.dynamic,
        textColor: textColor.value,
        titleColorSwatch: _createMaterialColor(textColor.value));
    currentSongId = songId;
    Hive.box('appPrefs').put("themePrimaryColor", (primaryColor.value!).toARGB32());
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  ThemeData _createThemeData(MaterialColor? primarySwatch, ThemeType themeType,
      {MaterialColor? titleColorSwatch, Color? textColor}) {
    if (themeType == ThemeType.dynamic) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: true),
      );

      final baseTheme = ThemeData(
          useMaterial3: false,
          primaryColor: primarySwatch![500],
          colorScheme: ColorScheme.fromSwatch(
              accentColor: primarySwatch[200],
              brightness: Brightness.dark,
              backgroundColor: primarySwatch[700],
              primarySwatch: primarySwatch),
          //accentColor: primarySwatch[200],
          dialogTheme: DialogThemeData(backgroundColor: primarySwatch[700]),
          cardColor: primarySwatch[600],
          primaryColorLight: primarySwatch[400],
          primaryColorDark: primarySwatch[700],
          //secondaryHeaderColor: primarySwatch[50],
          canvasColor: primarySwatch[700],
          //scaffoldBackgroundColor: primarySwatch[700],
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: primarySwatch[600],
              modalBarrierColor: primarySwatch[400]),
          navigationBarTheme: const NavigationBarThemeData(
            labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            )),
          ),
          iconTheme: IconThemeData(color: textColor ?? Colors.white70), // Explicitly set Icon color
          textTheme: TextTheme(
            titleLarge: const TextStyle(
                fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white),
            titleMedium: const TextStyle(
                fontWeight: FontWeight.w900, color: Colors.white),
            titleSmall: TextStyle(color: textColor ?? Colors.white70, fontWeight: FontWeight.normal),
            bodyMedium: TextStyle(color: textColor ?? Colors.white70),
            labelMedium: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 23,
                color: textColor ?? primarySwatch[50]),
            labelSmall: TextStyle(
                fontSize: 15,
                color: textColor ?? Colors.white70,
                letterSpacing: 0,
                fontWeight: FontWeight.normal),
          ),
          tabBarTheme: const TabBarThemeData(indicatorColor: Colors.white),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              linearTrackColor: (primarySwatch[300])!.computeLuminance() > 0.3
                  ? Colors.black54
                  : Colors.white70,
              color: textColor),
          navigationRailTheme: NavigationRailThemeData(
              backgroundColor: primarySwatch[700],
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: primarySwatch[100]),
              selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: primarySwatch[100], fontWeight: FontWeight.w900)),
          sliderTheme: SliderThemeData(
            inactiveTrackColor: primarySwatch[300],
            activeTrackColor: textColor,
            valueIndicatorColor: primarySwatch[400],
            thumbColor: Colors.white,
          ),
          textSelectionTheme: TextSelectionThemeData(
              cursorColor: primarySwatch[200],
              selectionColor: primarySwatch[200],
              selectionHandleColor: Colors.white),
          
          // Enhanced Visibility for Dynamic Theme
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) return Colors.white;
               return Colors.grey[400];
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) return primarySwatch[400];
               return Colors.black26;
            }),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold)),
              overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primarySwatch[500],
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
            hintStyle: TextStyle(color: Colors.white54),
            labelStyle: TextStyle(color: Colors.white),
            floatingLabelStyle: TextStyle(color: Colors.white),
            suffixIconColor: Colors.white70,
            prefixIconColor: Colors.white70,
          ),
          //scaffoldBackgroundColor: primarySwatch[700]
          );
      return baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Nunito',
      ));
    } else if (themeType == ThemeType.dark) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: true),
      );
      final baseTheme = ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          canvasColor: Colors.black,
          primaryColor: Colors.black,
          primaryColorDark: Colors.black,
          primaryColorLight: Colors.grey[850],
          iconTheme: const IconThemeData(color: Colors.white),
          colorScheme: ColorScheme.fromSwatch(
              accentColor: Colors.grey[700], brightness: Brightness.dark),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              color: Colors.grey[700], linearTrackColor: Colors.white),
          textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              titleSmall: TextStyle(fontWeight: FontWeight.normal),
              labelMedium: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 23,
              ),
              labelSmall: TextStyle(
                fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.normal),
              bodyMedium: TextStyle(color: Colors.grey)),
          navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Colors.black,
              selectedIconTheme: IconThemeData(
                color: Colors.white,
              ),
              unselectedIconTheme: IconThemeData(color: Colors.white38),
              selectedLabelTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: Colors.white38, fontWeight: FontWeight.w900)),
          bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.black, modalBarrierColor: Colors.black),
          navigationBarTheme: const NavigationBarThemeData(
            labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            )),
          ),
          sliderTheme: const SliderThemeData(
            //base bar color
            inactiveTrackColor: Colors.white30,
            //buffered progress
            activeTrackColor: Colors.white,
            //progress bar color
            valueIndicatorColor: Colors.black38,
            thumbColor: Colors.white,
          ),
          textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.grey[700],
              selectionColor: Colors.grey[700],
              selectionHandleColor: Colors.grey[700]),
          inputDecorationTheme: const InputDecorationTheme(
              focusColor: Colors.white,
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white))));
      return baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Nunito',
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white, // Force WHITE background
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: true), // Force contrast
      );
      
      const MaterialColor primarySwatch = Colors.grey;
      
      final baseTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          canvasColor: Colors.white,
          primarySwatch: primarySwatch,
          colorScheme: ColorScheme.fromSwatch(
              primarySwatch: primarySwatch,
              accentColor: Colors.black,
              backgroundColor: Colors.white,
              cardColor: Colors.white,
              brightness: Brightness.light).copyWith(
                surface: Colors.white,
                onSurface: Colors.black,
                secondary: Colors.grey[200], 
                onSecondary: Colors.black,   
                primary: Colors.black,
                onPrimary: Colors.white,
              ),
          primaryColor: Colors.white, // FIXED: Make App Bar Background WHITE
          primaryColorLight: Colors.grey[200],
          scaffoldBackgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black), // Black icons
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black, // Balck text/icons in AppBar
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark, // Dark icons on top
              statusBarBrightness: Brightness.light, // for iOS
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
              linearTrackColor: Colors.black12, color: Colors.black),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
          ),
          textTheme: TextTheme(
              titleLarge: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              titleMedium: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black, // Explicitly black
              ),
              titleSmall: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
              labelMedium: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 23,
                color: Colors.black,
              ),
              labelSmall: const TextStyle(
                  fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.normal, color: Colors.black54),
              bodyMedium: TextStyle(color: Colors.grey[900]),
          ),
          navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Colors.white,
              selectedIconTheme: IconThemeData(color: Colors.black),
              unselectedIconTheme: IconThemeData(color: Colors.grey),
              selectedLabelTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w900)),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.black87,
            contentTextStyle: TextStyle(color: Colors.white),
            actionTextColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white, modalBarrierColor: Colors.black12),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Colors.black.withValues(alpha: 0.1), // Subtle Grey
            iconTheme: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) {
                 return const IconThemeData(color: Colors.black);
               }
               return const IconThemeData(color: Colors.black54); 
            }),
            labelTextStyle: const WidgetStatePropertyAll(TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            )),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.black, foregroundColor: Colors.white),
          sliderTheme: const SliderThemeData(
            inactiveTrackColor: Colors.black12,
            activeTrackColor: Colors.black,
            valueIndicatorColor: Colors.black,
            thumbColor: Colors.black,
          ),
          inputDecorationTheme: const InputDecorationTheme(
              focusColor: Colors.black,
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black))),
          textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.grey[700],
              selectionColor: Colors.grey[300],
              selectionHandleColor: Colors.grey[700]), 
      );
      return baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Nunito',
      ));
    }
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff, g = (color.g * 255.0).round() & 0xff, b = (color.b * 255.0).round() & 0xff;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  Future<void> setWindowsTitleBarColor(Color color) async {
    if (!GetPlatform.isWindows) return;
    try {
      Future.delayed(
          const Duration(milliseconds: 350),
          () async => await platform.invokeMethod('setTitleBarColor', {
                'r': (color.r * 255.0).round() & 0xff,
                'g': (color.g * 255.0).round() & 0xff,
                'b': (color.b * 255.0).round() & 0xff,
              }));
    } on PlatformException catch (e) {
      printERROR("Failed to set title bar color: ${e.message}");
    }
  }
}

extension ComplementaryColor on Color {
  Color get complementaryColor => getComplementaryColor(this);
  Color getComplementaryColor(Color color) {
    int r = 255 - ((color.r * 255.0).round() & 0xff);
    int g = 255 - ((color.g * 255.0).round() & 0xff);
    int b = 255 - ((color.b * 255.0).round() & 0xff);
    return Color.fromARGB(((color.a * 255.0).round() & 0xff), r, g, b);
  }
}

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  Color withSaturation(double saturation) {
    return hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();
  }

  Color withLightness(double lightness) {
    return hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();
  }

  Color withHue(double hue) {
    return hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16)).withAlpha(0xFF);
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${((a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}';
}

enum ThemeType {
  dynamic,
  system,
  dark,
  light,
  automatic,
}
