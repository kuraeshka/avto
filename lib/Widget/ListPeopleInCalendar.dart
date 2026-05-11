import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> ListPeople(BuildContext context, String calendarId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('calendars')
      .doc(calendarId)
      .collection('members')
      .get();

  final List<Map<String, dynamic>> participants = [];

  for (var doc in snapshot.docs) {
    final uid = doc.id;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = userDoc.data();

    participants.add({
      'name': data?['name'] ?? 'Без имени',
      'avatar': data?['avatar'] ?? 0,
    });
  }

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white70,
        title: const Text("Список участников"),
        content: SizedBox(
          width: 300,
          child: participants.isEmpty
              ? const Text("Участников нет")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (_, i) {
                    final user = participants[i];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(
                          'assets/avatarsp/avatar${user['avatar']}.png',
                        ),
                      ),
                      title: Text(user['name']),
                    );
                  },
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