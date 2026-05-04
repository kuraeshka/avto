import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void CelebrationAdd(
  BuildContext context,
  String calendarId,
) {
  final titleController = TextEditingController();
  final placeController = TextEditingController();
  final performersController = TextEditingController();
  final equipmentController = TextEditingController();

  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(child: Text("Добавление события")),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Название события',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Место проведения',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: performersController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Исполнители',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: equipmentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Оборудование',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                      selectedDate == null
                          ? 'Дата не выбрана'
                          : 'Дата: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
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
                  if (selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пожалуйста, выберите дату'),
                      ),
                    );
                    return;
                  }

                  final title = titleController.text.isNotEmpty
                      ? titleController.text
                      : 'Без названия';

                  // ✅ Сохраняем в Firestore
                  await FirebaseFirestore.instance
                      .collection('calendars')
                      .doc(calendarId)
                      .collection('events')
                      .add({
                        'name': title,
                        'place': placeController.text,
                        'performers': performersController.text,
                        'equipment': equipmentController.text,
                        'date': selectedDate,
                      });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Событие "$title" добавлено')),
                  );
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