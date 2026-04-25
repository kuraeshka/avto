import 'package:avto/frontend/Screens/view.dart';

final router = {
  '/home': (context) => CoreScreen(calendarId: '',),
  '/Rega': (context) => RegaWindow(),
  '/Profil': (context) => ProfilWindow(),
  '/Settings': (context) => SettingsWindow(),
  '/Hello': (context) => HelloWindow(),
};
