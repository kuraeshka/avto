import 'package:avto/Widget/choice_Theme.dart';
import 'package:flutter/material.dart';
import 'package:avto/Core/Theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.id,
    required this.name,
    required this.objectName,
    required this.objectImage,
    required this.equipment,
    required this.furniture,
    required this.checkList,
    required this.canEdit,
    required this.eventDescription,
    required this.calendarId,
  });

 final String calendarId;
  final String name;
  final String eventDescription;
  final String id;
  final String objectName;
  final String objectImage;

  final List<String> equipment;
  final List<String> furniture;

  final List<Map<String, dynamic>> checkList;

  final bool canEdit;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String eventDescription = "";
  @override
  void initState() {
    super.initState();

    eventDescription = widget.eventDescription;
    _descriptionController.text = eventDescription;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ThemeDataChoice.value == White_ThemeData
                ? const AssetImage("assets/images/seaback.jpg")
                : const AssetImage("assets/images/greyback.jpg"),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Container(
                width: 900,

                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(color: Colors.white54),

                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /// Кнопка назад
                    /// Заголовок со стрелкой назад
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// Описание
                    TextField(
                      controller: _descriptionController,
                      enabled: widget.canEdit,
                      maxLines: 4,

                      style: const TextStyle(color: Colors.white, fontSize: 16),

                      decoration: InputDecoration(
                        labelText: "Описание мероприятия",
                        labelStyle: const TextStyle(color: Colors.white70),

                        hintText: "Введите описание мероприятия",
                        hintStyle: const TextStyle(color: Colors.white54),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white),
                        ),

                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 2 колонки
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _objectCard(),

                              const SizedBox(height: 15),

                              _listCard(
                                "Оборудование",
                                Icons.build,
                                widget.equipment,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            children: [
                              _checkListCard(),

                              const SizedBox(height: 15),

                              _listCard(
                                "Мебель",
                                Icons.chair,
                                widget.furniture,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (widget.canEdit)
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),

                          onPressed: () async {
  try {
    await FirebaseFirestore.instance
        .collection("calendar")
        .doc(widget.calendarId)
        .collection("events")
        .doc(widget.id)
        .update({
          "eventDescription": _descriptionController.text.trim(),
          "checkList": widget.checkList.map((task) {
            return {
              "task": task["task"],
              "done": task["done"] ?? false,
              "users": task["users"] ?? [],
            };
          }).toList(),
        });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Изменения успешно сохранены"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ошибка сохранения: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                          icon: const Icon(Icons.save),

                          label: const Text("Сохранить изменения"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ------------------------
  /// Карточка объекта
  /// ------------------------
  Widget _objectCard() {
    return _card(
      Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),

            child: SizedBox(
              height: 220,

              width: double.infinity,

              child: widget.objectImage.isNotEmpty
                  ? Image.network(widget.objectImage, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],

                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(Icons.image_not_supported, size: 50),

                          Text("Фото отсутствует"),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            widget.objectName,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ------------------------
  /// Чеклист
  /// ------------------------
  Widget _checkListCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.check_circle),

              SizedBox(width: 8),

              Text(
                "Чеклист",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (widget.checkList.isEmpty)
            const Text("Задач нет")
          else
            ...widget.checkList.map((task) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,

                value: task["done"] ?? false,

                onChanged: widget.canEdit
                    ? (value) {
                        setState(() {
                          task["done"] = value;
                        });
                      }
                    : null,

                title: Text(task["task"] ?? ""),

                subtitle: Text("Исполнитель: ${task["user"] ?? "Не назначен"}"),
              );
            }),
        ],
      ),
    );
  }

  /// ------------------------
  /// Список мебели/оборудования
  /// ------------------------
  Widget _listCard(String title, IconData icon, List<String> items) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon),

              const SizedBox(width: 8),

              Text(
                title,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (items.isEmpty)
            const Text("Нет данных")
          else
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),

                child: Text("• $e", style: const TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  /// ------------------------
  /// Общая карточка
  /// ------------------------
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),

        borderRadius: BorderRadius.circular(20),

        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),

      child: child,
    );
  }
}
