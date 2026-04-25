import 'package:avto/Core/Theme.dart';
import 'package:flutter/material.dart';

final ThemeDataChoice = ValueNotifier<ThemeData>(White_ThemeData);

void choice() {
 ThemeDataChoice.value = ThemeDataChoice.value == White_ThemeData 
      ? Black_ThemeData 
      : White_ThemeData;
}