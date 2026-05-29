import 'package:avto/Core/Theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ThemeDataChoice = ValueNotifier<ThemeData>(White_ThemeData);

Future<void> choice() async {
  final prefs = await SharedPreferences.getInstance();

  final isDark = ThemeDataChoice.value == White_ThemeData;

  ThemeDataChoice.value =
      isDark ? Black_ThemeData : White_ThemeData;

  await prefs.setBool(
    'isDarkTheme',
    ThemeDataChoice.value == Black_ThemeData,
  );
}
Future<void> loadTheme() async {
  final prefs = await SharedPreferences.getInstance();

  final isDark = prefs.getBool('isDarkTheme') ?? false;
  
  ThemeDataChoice.value =
      isDark ? Black_ThemeData : White_ThemeData;
}