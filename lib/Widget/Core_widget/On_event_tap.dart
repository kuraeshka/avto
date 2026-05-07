
import 'package:avto/Widget/Core_widget/Edit_event.dart';
import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void onEventTap(Event event, BuildContext context, String calendarId) async {
    List<String> equipmentNames = [];
    List<String> performerNames = [];
    String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
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
            (name != null && name.toString().isNotEmpty)
                ? name.toString()
                : id,
          );
        } else {
          performerNames.add(id);
        }
      } catch (_) {
        performerNames.add(id);
      }
    }

    for (var e in event.equipment) {
      if (e.trim().isNotEmpty) {
        equipmentNames.add(e);
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(event.title),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📅 Дата: ${event.start.toString().split(' ')[0]}",
              ),

              const SizedBox(height: 5),

              Text(
                "⏰ ${formatTime(event.start)} - ${formatTime(event.end)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text("📍 ${event.place}"),

              const SizedBox(height: 10),

              const Text("👥 Участники:"),

              ...performerNames.map(
                (p) => Text("• $p"),
              ),

              const SizedBox(height: 10),

              const Text("🛠 Оборудование:"),

              ...equipmentNames.map(
                (e) => Text("• $e"),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ShowEditEventDialog(event, context, calendarId);
            },
            child: const Text("Редактировать"),
          ),

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