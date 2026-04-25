import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/BlueWaterback.jpg"), // Путь к изображению
          fit: BoxFit.cover, // Растянуть на весь экран
        ),
      ),
      child: child,
    );
  }
}