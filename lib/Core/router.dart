import 'package:avto/frontend/Screens/view.dart';
import 'package:flutter/material.dart';

final router = {
  '/home': (context) => CoreScreen(calendarId: ''),
  '/Rega': (context) => RegaWindow(),
  '/Profil': (context) => ProfilWindow(),
  '/Settings': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args == null || args is! String || args.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Ошибка: calendarId пустой")),
      );
    }

    return SettingsWindow(calendarId: args);
  },
  '/Hello': (context) => HelloWindow(),
};
