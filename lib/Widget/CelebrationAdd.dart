import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void CelebrationAdd(BuildContext context, String calendarId) {
  final titleController = TextEditingController();
  final placeController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? selectedDate;

  List<String> selectedPerformers = [];
  List<Map<String, dynamic>> selectedEquipment = [];
  List<Map<String, dynamic>> objects = [];
  Map<String, dynamic>? selectedObject;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> equipment = [];

  /// 🔥 ВАЖНОСТЬ
  String selectedImportance = "blue";

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> loadData() async {
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

            final calendarDoc = await FirebaseFirestore.instance
                .collection('calendars')
                .doc(calendarId)
                .get();

            final eq = (calendarDoc.data()?['equipment'] ?? [])
                .cast<Map<String, dynamic>>();

            final loadedObjects = List<Map<String, dynamic>>.from(
              calendarDoc.data()?['objects'] ?? [],
            );
            setState(() {
              members = loadedMembers;
              equipment = eq;
              objects = loadedObjects;
            });

            setState(() {
              members = loadedMembers;
              equipment = eq;
            });
          }

          if (members.isEmpty && equipment.isEmpty) {
            loadData();
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Container(
              width: 800,
              height: 750,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// ШАПКА
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.event, color: Colors.white, size: 35),
                        SizedBox(width: 10),
                        Text(
                          "Новое событие",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// ОСНОВНОЙ КОНТЕНТ
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          /// НАЗВАНИЕ
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: titleController,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.title),
                                      labelText: "Название события",
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    value: selectedObject,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.location_city),
                                      labelText: "Объект",
                                    ),
                                    items: objects.map((obj) {
                                      return DropdownMenuItem(
                                        value: obj,
                                        child: Text(
                                          obj['name'] ?? 'Без названия',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedObject = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// ВАЖНОСТЬ
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Степень важности",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text("Обычная"),
                                selected: selectedImportance == "blue",
                                onSelected: (_) {
                                  setState(() {
                                    selectedImportance = "blue";
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text("Высокая"),
                                selected: selectedImportance == "red",
                                onSelected: (_) {
                                  setState(() {
                                    selectedImportance = "red";
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text("Критическая"),
                                selected: selectedImportance == "black",
                                onSelected: (_) {
                                  setState(() {
                                    selectedImportance = "black";
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          /// ИСПОЛНИТЕЛИ
                          ExpansionTile(
                            leading: const Icon(Icons.people),
                            title: const Text("Исполнители"),
                            children: [
                              SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  itemCount: members.length,
                                  itemBuilder: (context, index) {
                                    final m = members[index];
                                    final uid = m['uid'];

                                    final isSelected = selectedPerformers
                                        .contains(uid);

                                    return CheckboxListTile(
                                      value: isSelected,
                                      title: Text(m['name']),
                                      secondary: CircleAvatar(
                                        backgroundImage: AssetImage(
                                          'assets/avatarsp/avatar${m['avatar']}.png',
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedPerformers.add(uid);
                                          } else {
                                            selectedPerformers.remove(uid);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// ОБОРУДОВАНИЕ
                          ExpansionTile(
                            leading: const Icon(Icons.build),
                            title: const Text("Оборудование"),
                            children: [
                              SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  itemCount: equipment.length,
                                  itemBuilder: (context, index) {
                                    final item = equipment[index];

                                    final isSelected = selectedEquipment
                                        .contains(item);

                                    return CheckboxListTile(
                                      value: isSelected,
                                      title: Text(item['name'] ?? ''),
                                      subtitle: Text(item['place'] ?? ''),
                                      secondary: const CircleAvatar(
                                        child: Icon(Icons.build),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedEquipment.add(item);
                                          } else {
                                            selectedEquipment.remove(item);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          /// ДАТА И ВРЕМЯ
                          Card(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ListTile(
                                    leading: const Icon(Icons.calendar_month),
                                    title: Text(
                                      selectedDate == null
                                          ? "Дата"
                                          : selectedDate!.toString().split(
                                              ' ',
                                            )[0],
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );

                                      if (picked != null) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                Expanded(
                                  child: ListTile(
                                    leading: const Icon(Icons.play_arrow),
                                    title: Text(
                                      startTime == null
                                          ? "Начало"
                                          : startTime!.format(context),
                                    ),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );

                                      if (picked != null) {
                                        setState(() {
                                          startTime = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                Expanded(
                                  child: ListTile(
                                    leading: const Icon(Icons.stop),
                                    title: Text(
                                      endTime == null
                                          ? "Конец"
                                          : endTime!.format(context),
                                    ),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );

                                      if (picked != null) {
                                        setState(() {
                                          endTime = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// КНОПКИ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Отмена"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Создать"),
                          onPressed: () async {
                            if (selectedObject == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Выберите объект"),
                                ),
                              );
                              return;
                            }

                            if (selectedDate == null ||
                                startTime == null ||
                                endTime == null) {
                              return;
                            }

                            final startDate = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              startTime!.hour,
                              startTime!.minute,
                            );

                            final endDate = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              endTime!.hour,
                              endTime!.minute,
                            );

                            await FirebaseFirestore.instance
                                .collection('calendars')
                                .doc(calendarId)
                                .collection('events')
                                .add({
                                  'name': titleController.text,

                                  /// ОБЪЕКТ
                                  'place': selectedObject!['name'],

                                  /// ВРЕМЯ
                                  'start': startDate,
                                  'end': endDate,

                                  /// КООРДИНАТЫ
                                  'latitude': selectedObject!['latitude'],
                                  'longitude': selectedObject!['longitude'],

                                  /// ИСПОЛНИТЕЛИ И ОБОРУДОВАНИЕ
                                  'performers': selectedPerformers,
                                  'equipment': selectedEquipment,

                                  /// ВАЖНОСТЬ
                                  'importance': selectedImportance,
                                });

                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
