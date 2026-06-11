import 'package:avto/Widget/Core_widget/Edit_event.dart';
import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

Future<void> onEventTap(
  Event event,
  BuildContext context,
  String calendarId,
) async {
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
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// =========================
              /// ЗАГОЛОВОК
              /// =========================
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.event, size: 50, color: Colors.blue),

                    const SizedBox(height: 10),

                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// =========================
              /// ДАТА
              /// =========================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(event.start.toString().split(' ')[0]),
                ),
              ),

              const SizedBox(height: 10),

              /// =========================
              /// ВРЕМЯ
              /// =========================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    "${formatTime(event.start)} - ${formatTime(event.end)}",
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// =========================
              /// ОБЪЕКТ
              /// =========================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(
                    event.place.isEmpty ? "Объект не указан" : event.place,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// =========================
              /// КАРТА
              /// =========================
              if (event.latitude != null && event.longitude != null)
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latlng.LatLng(
                        event.latitude!,
                        event.longitude!,
                      ),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latlng.LatLng(
                              event.latitude!,
                              event.longitude!,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              /// =========================
              /// УЧАСТНИКИ
              /// =========================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Участники",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(),

                      ...performerNames.map(
                        (p) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.person),
                          title: Text(p),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// =========================
              /// ОБОРУДОВАНИЕ
              /// =========================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Оборудование",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(),

                      ...equipmentNames.map(
                        (e) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.build),
                          title: Text(e),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// =========================
              /// КНОПКИ
              /// =========================
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (currentUserRole == "executor" &&
                      !event.performers.contains(currentUid))
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text("Записаться"),
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
                            const SnackBar(
                              content: Text("Вы записались на событие"),
                            ),
                          );
                        }
                      },
                    ),

                  if (currentUserRole == "executor" &&
                      event.performers.contains(currentUid))
                    FilledButton.icon(
                      icon: const Icon(Icons.person_remove),
                      label: const Text("Отменить запись"),
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
                    ),

                  if (canEdit)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Редактировать"),
                      onPressed: () {
                        Navigator.pop(context);

                        ShowEditEventDialog(event, context, calendarId);
                      },
                    ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Закрыть"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
