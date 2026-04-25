import 'package:flutter/material.dart';
import 'package:avto/Core/router.dart';
import 'package:avto/backend_firebase/AuthGate.dart';
import 'package:avto/Widget/Widget.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeDataChoice,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MCL',
          theme: theme,

          home: const AuthGate(),

          routes: router,
        );
      },
    );
  }
}
