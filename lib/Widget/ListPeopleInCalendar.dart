import 'package:flutter/material.dart';


  List<String> participants = ['Иван', 'Петр', 'Сергей','Иван', 'Петр', 'Сергей','Иван', 'Петр', 'Сергей','Иван', 'Петр', 'Сергей',];
void ListPeople(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Список участников"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: participants
                .map((name) => ListTile(title: Text(name)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
