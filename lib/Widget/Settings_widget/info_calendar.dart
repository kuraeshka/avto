import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalendarInfoWidget extends StatelessWidget {
  final String copyCode;

  const CalendarInfoWidget({super.key, required this.copyCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text("Имя календаря"),
          const SizedBox(height: 20),
          ListTile(title: const Text("Имя"), onTap: () {}),
          const SizedBox(height: 30),
          const Text("Код подключения"),
          const SizedBox(height: 20),
          ListTile(
            title: Text(copyCode),
            trailing: const Icon(Icons.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: copyCode)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Текст скопирован в буфер обмена'),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
