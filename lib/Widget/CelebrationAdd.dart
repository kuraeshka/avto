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

            setState(() {
              members = loadedMembers;
              equipment = eq;
            });
          }

          if (members.isEmpty && equipment.isEmpty) {
            loadData();
          }

          return AlertDialog(
            title: const Text("Добавление события"),

            content: SizedBox(
              width: double.maxFinite,
              height: 700,

              child: Column(
                children: [
                  /// =======================
                  /// НАЗВАНИЕ
                  /// =======================
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Название"),
                  ),

                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(labelText: "Место"),
                  ),

                  const SizedBox(height: 10),

                  /// =======================
                  /// ВАЖНОСТЬ
                  /// =======================
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Степень важности",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [
                      /// ⚫ ЧЁРНЫЙ
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImportance = "black";
                          });
                        },

                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black,

                          child: selectedImportance == "black"
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),

                      /// 🔵 СИНИЙ
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImportance = "blue";
                          });
                        },

                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,

                          child: selectedImportance == "blue"
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),

                      /// 🔴 КРАСНЫЙ
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImportance = "red";
                          });
                        },

                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.red,

                          child: selectedImportance == "red"
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// =======================
                  /// ИСПОЛНИТЕЛИ
                  /// =======================
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
                              setState(() {
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

                  /// =======================
                  /// ОБОРУДОВАНИЕ
                  /// =======================
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
                              setState(() {
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

                  /// =======================
                  /// ДАТА
                  /// =======================
                  ListTile(
                    title: Text(
                      selectedDate == null
                          ? 'Дата не выбрана'
                          : selectedDate!.toLocal().toString().split(' ')[0],
                    ),

                    trailing: const Icon(Icons.calendar_today),

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

                  /// =======================
                  /// ВРЕМЯ НАЧАЛА
                  /// =======================
                  ListTile(
                    title: Text(
                      startTime == null
                          ? "Начало"
                          : "${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}",
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

                  /// =======================
                  /// ВРЕМЯ КОНЦА
                  /// =======================
                  ListTile(
                    title: Text(
                      endTime == null
                          ? "Конец"
                          : "${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}",
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
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () async {
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
                        'start': startDate,
                        'end': endDate,
                        'place': placeController.text,
                        'performers': selectedPerformers,
                        'equipment': selectedEquipment,

                        /// 🔥 ВАЖНОСТЬ
                        'importance': selectedImportance,
                      });

                  Navigator.pop(context);
                },

                child: const Text("Добавить"),
              ),
            ],
          );
        },
      );
    },
  );
}
