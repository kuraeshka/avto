import 'package:avto/frontend/Screens/view.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    final String calendarId = args;

    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return SettingsWindow(calendarId: calendarId, currentUserId: currentUserId);
  },
  '/ExecutorCalendar': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text("Ошибка передачи данных")),
      );
    }

    return ExecutorCalendarPage(
      calendarId: args['calendarId'],
      userId: args['userId'],
    );
  },
  '/ObjectsInfo': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return ObjectsInfoPage(calendarId: args['calendarId']);
  },
   '/objectsCalendar': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>;

    return ObjectsCalendarPage(
      calendarId: args['calendarId'],
    );
  },

  '/Hello': (context) => HelloWindow(),
};
