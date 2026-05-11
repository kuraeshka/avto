import 'package:avto/Widget/RowCalendar/FormAddCalendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void FormConnectCalendar(BuildContext context) {
  final TextEditingController codeController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Подключиться к календарю"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: "Код"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              final code = codeController.text;

              final query = await FirebaseFirestore.instance
                  .collection('calendars')
                  .where('code', isEqualTo: code)
                  .get();

              if (query.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Календарь не найден")),
                );
                return;
              }

              final calendar = query.docs.first;

              /// добавляем в members
              await FirebaseFirestore.instance
                  .collection('calendars')
                  .doc(calendar.id)
                  .collection('members')
                  .doc(userId)
                  .set({'role': 'observer'});

              /// добавляем пользователю
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('calendars')
                  .doc(calendar.id)
                  .set({
                'name': calendar['name'],
                'role': 'observer',
              });

              Navigator.pop(context);
            },
            child: const Text("Подключиться"),
          ),
          ElevatedButton(
              onPressed: () {
                FormAddCalendar(context);
              },
              child: const Text("Создать"),
            ),
        ],
      );
    },
  );
}