import 'package:avto/Widget/Settings_widget/info_calendar.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:flutter/material.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key});

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  String get copy_code => "КОД";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки календаря'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/seaback.jpg'),
            fit: BoxFit.cover,
          ),),
         child: Center(
        child: Container(
          width: 600,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
          child: Column(
            children: [
              Row(
                children: [
                  Avatar_set,
                  Expanded(
                    child: CalendarInfoWidget(
                      copyCode: copy_code, // ваша переменная с кодом
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    child: Expanded(
                      child: SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: participants
                                .map((name) => ListTile(title: Text(name)))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Expanded(
                      child: SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: participants
                                .map((name) => ListTile(title: Text(name)))
                                .toList(),
                          ),
                          
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              SizedBox( width: 400, height: 50,child: ElevatedButton(onPressed: () {}, child: Text("Выйти из календаря"))),
              SizedBox(height: 10,)
            ],
          ),
        ),
      ),),
    );
  }
}
