import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 테마 상태 클래스
class AppThemeState {
  final ThemeMode themeMode;

  AppThemeState({this.themeMode = ThemeMode.light});

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppThemeState copyWith({ThemeMode? themeMode}) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  // iOS 스타일 Light 모드 맵 스타일
  String get lightMapStyle => '''
  [
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#d4f1f9"}]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#fafafa"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#e8f5e9"}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "simplified"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#dddddd"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#999999"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.icon",
      "stylers": [{"visibility": "on"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.icon",
      "stylers": [{"visibility": "on"}]
    },
    {
      "featureType": "poi.business",
      "stylers": [{"visibility": "simplified"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#e5e5e5"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#e5e5e5"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#e5e5e5"}]
    }
  ]
  ''';

  // iOS 스타일 Dark 모드 맵 스타일 (텍스트 가독성 개선)
  String get darkMapStyle => '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [{"color": "#242424"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#1a2632"}]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [{"color": "#2d2d2d"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#424242"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#373737"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry",
      "stylers": [{"color": "#333333"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d5d5d5"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1f1f1f"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d5d5d5"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1f1f1f"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d5d5d5"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1f1f1f"}]
    },
    {
      "featureType": "administrative",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d5d5d5"}]
    },
    {
      "featureType": "administrative",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1f1f1f"}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "on"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#4a4a4a"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#444444"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#3a3a3a"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels",
      "stylers": [{"visibility": "on"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#e5e5e5"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1f1f1f"}]
    }
  ]
  ''';

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        highlightColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        highlightColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueGrey,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueGrey,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          onSecondary: Colors.white,
          surface: Colors.grey[800]!,
          onSurface: Colors.white,
        ),
      );
}

// 테마 상태 관리 NotifierProvider
class AppThemeNotifier extends StateNotifier<AppThemeState> {
  AppThemeNotifier() : super(AppThemeState());

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

// 테마 프로바이더
final appThemeProvider = StateNotifierProvider<AppThemeNotifier, AppThemeState>((ref) {
  return AppThemeNotifier();
});