import 'package:avto/Widget/RowCalendar/FormConnectCalendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void FormAddCalendar(BuildContext context) {
  final TextEditingController nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Создать календарь"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Название"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              final name = nameController.text;

              final doc = await FirebaseFirestore.instance
                  .collection('calendars')
                  .add({
                'name': name,
                'code': DateTime.now().millisecondsSinceEpoch.toString(),
                'ownerId': userId,
              });

              /// 🔥 добавляем пользователя в календарь
              await FirebaseFirestore.instance
                  .collection('calendars')
                  .doc(doc.id)
                  .collection('members')
                  .doc(userId)
                  .set({'role': 'admin'});

              /// 🔥 добавляем календарь пользователю
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('calendars')
                  .doc(doc.id)
                  .set({
                'name': name,
                'role': 'admin',
              });

              Navigator.pop(context);
            },
            child: const Text("Создать"),
          ),
        ],
      );
    },
  );
}