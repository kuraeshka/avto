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

  final String currentUserId =
      FirebaseAuth.instance.currentUser!.uid;

  return SettingsWindow(
    calendarId: calendarId,
    currentUserId: currentUserId,
  );
},
  '/Hello': (context) => HelloWindow(),
};
