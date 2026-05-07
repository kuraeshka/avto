import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void ShowEditEventDialog(Event event, BuildContext context, String calendarId) {
  final titleController = TextEditingController(text: event.title);

  final placeController = TextEditingController(text: event.place);
  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  DateTime start = event.start;
  DateTime end = event.end;

  /// ВЫБРАННЫЕ
  List<String> selectedPerformers = List<String>.from(event.performers);

  List<Map<String, dynamic>> selectedEquipment = [];

  /// ДАННЫЕ
  List<Map<String, dynamic>> members = [];

  List<Map<String, dynamic>> equipment = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          /// ЗАГРУЗКА
          Future<void> loadData() async {
            /// УЧАСТНИКИ
            final membersSnap = await FirebaseFirestore.instance
                .collection('calendars')
                .doc(calendarId)
                .collection('members')
                .get();

            List<Map<String, dynamic>> loadedMembers = [];

            for (var doc in membersSnap.docs) {
              final uid = doc.id;

              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();

              final data = userDoc.data();

              loadedMembers.add({
                'uid': uid,
                'name': data?['name'] ?? uid,
                'avatar': data?['avatar'] ?? 0,
              });
            }

            /// ОБОРУДОВАНИЕ
            final calendarDoc = await FirebaseFirestore.instance
                .collection('calendars')
                .doc(calendarId)
                .get();

            final eq = (calendarDoc.data()?['equipment'] ?? [])
                .cast<Map<String, dynamic>>();

            /// ВОССТАНАВЛИВАЕМ ВЫБРАННОЕ ОБОРУДОВАНИЕ
            List<Map<String, dynamic>> selectedEq = [];

            for (var item in eq) {
              final itemName = item['name']?.toString();

              if (event.equipment.contains(itemName)) {
                selectedEq.add(item);
              }
            }

            setModalState(() {
              members = loadedMembers;
              equipment = eq;
              selectedEquipment = selectedEq;
            });
          }

          if (members.isEmpty && equipment.isEmpty) {
            loadData();
          }

          return AlertDialog(
            title: const Text("Редактирование события"),

            content: SizedBox(
              width: 600,
              height: 700,

              child: Column(
                children: [
                  /// =========================
                  /// НАЗВАНИЕ
                  /// =========================
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Название"),
                  ),

                  const SizedBox(height: 10),

                  /// =========================
                  /// МЕСТО
                  /// =========================
                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(labelText: "Место"),
                  ),

                  const SizedBox(height: 20),

                  /// =========================
                  /// УЧАСТНИКИ
                  /// =========================
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Исполнители",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];

                        final uid = m['uid'];

                        final isSelected = selectedPerformers.contains(uid);

                        return Card(
                          child: CheckboxListTile(
                            value: isSelected,

                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedPerformers.add(uid);
                                } else {
                                  selectedPerformers.remove(uid);
                                }
                              });
                            },

                            title: Text(m['name']),

                            secondary: CircleAvatar(
                              backgroundImage: AssetImage(
                                'assets/avatarsp/avatar${m['avatar']}.png',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// =========================
                  /// ОБОРУДОВАНИЕ
                  /// =========================
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Оборудование",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: equipment.length,
                      itemBuilder: (context, index) {
                        final item = equipment[index];

                        final isSelected = selectedEquipment.contains(item);

                        return Card(
                          child: CheckboxListTile(
                            value: isSelected,

                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedEquipment.add(item);
                                } else {
                                  selectedEquipment.remove(item);
                                }
                              });
                            },

                            title: Text(item['name'] ?? ''),

                            subtitle: Text(item['place'] ?? ''),

                            secondary: const CircleAvatar(
                              child: Icon(Icons.build),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// =========================
                  /// ВРЕМЯ
                  /// =========================
                  ListTile(
                    title: Text("Начало: ${formatTime(start)}"),

                    trailing: const Icon(Icons.access_time),

                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(start),
                      );

                      if (picked != null) {
                        setModalState(() {
                          start = DateTime(
                            start.year,
                            start.month,
                            start.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),

                  ListTile(
                    title: Text("Конец: ${formatTime(end)}"),

                    trailing: const Icon(Icons.access_time),

                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(end),
                      );

                      if (picked != null) {
                        setModalState(() {
                          end = DateTime(
                            end.year,
                            end.month,
                            end.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            actions: [
              /// =========================
              /// УДАЛЕНИЕ
              /// =========================
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),

                label: const Text(
                  "Удалить",
                  style: TextStyle(color: Colors.red),
                ),

                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Удаление"),

                      content: const Text("Удалить событие?"),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text("Нет"),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text("Да"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await FirebaseFirestore.instance
                      .collection('calendars')
                      .doc(calendarId)
                      .collection('events')
                      .doc(event.id)
                      .delete();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),

              /// =========================
              /// ОТМЕНА
              /// =========================
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Отмена"),
              ),

              /// =========================
              /// СОХРАНИТЬ
              /// =========================
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('calendars')
                      .doc(calendarId)
                      .collection('events')
                      .doc(event.id)
                      .update({
                        'name': titleController.text.trim(),

                        'place': placeController.text.trim(),

                        'start': Timestamp.fromDate(start),

                        'end': Timestamp.fromDate(end),

                        'performers': selectedPerformers,

                        'equipment': selectedEquipment,
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },

                child: const Text("Сохранить"),
              ),
            ],
          );
        },
      );
    },
  );
}
