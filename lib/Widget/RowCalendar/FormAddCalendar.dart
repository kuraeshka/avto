import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 🔥 генерация короткого уникального кода
String generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final now = DateTime.now().millisecondsSinceEpoch;

  return List.generate(
    6,
    (index) => chars[(now + index * 37) % chars.length],
  ).join();
}

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
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) return;

              final userId = user.uid;
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Введите название")),
                );
                return;
              }

              /// 🔥 создаём код
              final code = generateCode();

              /// 🔥 создаём календарь
              final doc = await FirebaseFirestore.instance
                  .collection('calendars')
                  .add({
                'name': name,
                'code': code,
                'ownerId': userId,

                /// 🔥 для настроек
                'avatar': 0,
                'participants': [userId],
                'equipment': [],

                'createdAt': FieldValue.serverTimestamp(),
              });

              /// 🔥 добавляем пользователя в members
              await FirebaseFirestore.instance
                  .collection('calendars')
                  .doc(doc.id)
                  .collection('members')
                  .doc(userId)
                  .set({
                'role': 'admin',
              });

              /// 🔥 добавляем календарь пользователю
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('calendars')
                  .doc(doc.id)
                  .set({
                'name': name,
                'role': 'admin',
                'calendarId': doc.id,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Календарь создан. Код: $code"),
                ),
              );
            },
            child: const Text("Создать"),
          ),
        ],
      );
    },
  );
}