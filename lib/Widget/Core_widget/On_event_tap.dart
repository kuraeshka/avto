import 'package:avto/Widget/Core_widget/Edit_event.dart';
import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> onEventTap(Event event, BuildContext context, String calendarId) async {
  List<String> equipmentNames = [];
  List<String> performerNames = [];

  String currentUserRole = "observer";

  /// =========================================
  /// ЗАГРУЗКА РОЛИ
  /// =========================================
  final currentUid = FirebaseAuth.instance.currentUser!.uid;

  final memberDoc = await FirebaseFirestore.instance
      .collection('calendars')
      .doc(calendarId)
      .collection('members')
      .doc(currentUid)
      .get();

  currentUserRole = memberDoc.data()?['role'] ?? 'observer';

  /// МОЖНО ЛИ РЕДАКТИРОВАТЬ
  final bool canEdit =
      currentUserRole == "admin" || currentUserRole == "manager";

  /// =========================================
  /// ФОРМАТ ВРЕМЕНИ
  /// =========================================
  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// =========================================
  /// ЗАГРУЗКА УЧАСТНИКОВ
  /// =========================================
  for (var id in event.performers) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data();

        final name = data?['name'];

        performerNames.add(
          (name != null && name.toString().isNotEmpty) ? name.toString() : id,
        );
      } else {
        performerNames.add(id);
      }
    } catch (_) {
      performerNames.add(id);
    }
  }

  /// =========================================
  /// ОБОРУДОВАНИЕ
  /// =========================================
  for (var e in event.equipment) {
    if (e.trim().isNotEmpty) {
      equipmentNames.add(e);
    }
  }

  if (!context.mounted) return;

  /// =========================================
  /// DIALOG
  /// =========================================
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(event.title),

      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text("📅 Дата: ${event.start.toString().split(' ')[0]}"),

            const SizedBox(height: 5),

            Text(
              "⏰ ${formatTime(event.start)} - ${formatTime(event.end)}",

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("📍 ${event.place}"),

            const SizedBox(height: 10),

            const Text("👥 Участники:"),

            ...performerNames.map((p) => Text("• $p")),

            const SizedBox(height: 10),

            const Text("🛠 Оборудование:"),

            ...equipmentNames.map((e) => Text("• $e")),
          ],
        ),
      ),

      actions: [
        /// =========================================
        /// ЗАПИСАТЬСЯ НА СОБЫТИЕ
        /// =========================================
        if (currentUserRole == "executor" &&
            !event.performers.contains(currentUid))
          TextButton(
            onPressed: () async {
              final eventRef = FirebaseFirestore.instance
                  .collection('calendars')
                  .doc(calendarId)
                  .collection('events')
                  .doc(event.id);

              await eventRef.update({
                'performers': FieldValue.arrayUnion([currentUid]),
              });

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Вы записались на событие")),
                );
              }
            },

            child: const Text("Записаться"),
          ),

        /// =========================================
        /// ОТМЕНИТЬ ЗАПИСЬ
        /// =========================================
        if (currentUserRole == "executor" &&
            event.performers.contains(currentUid))
          TextButton(
            onPressed: () async {
              final eventRef = FirebaseFirestore.instance
                  .collection('calendars')
                  .doc(calendarId)
                  .collection('events')
                  .doc(event.id);

              await eventRef.update({
                'performers': FieldValue.arrayRemove([currentUid]),
              });

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Запись отменена")),
                );
              }
            },

            child: const Text("Отменить запись"),
          ),

        /// =========================================
        /// РЕДАКТИРОВАТЬ
        /// =========================================
        if (canEdit)
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              ShowEditEventDialog(event, context, calendarId);
            },

            child: const Text("Редактировать"),
          ),

        /// =========================================
        /// ЗАКРЫТЬ
        /// =========================================
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text("Закрыть"),
        ),
      ],
    ),
  );
}
