import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/choice_Theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ObjectEvent {
  final String id;
  final String title;
  final String place;
  final DateTime start;
  final DateTime end;
  final String importance;

  ObjectEvent({
    required this.id,
    required this.title,
    required this.place,
    required this.start,
    required this.end,
    required this.importance,
  });
}

class ObjectsCalendarPage extends StatefulWidget {
  final String calendarId;

  const ObjectsCalendarPage({super.key, required this.calendarId});

  @override
  State<ObjectsCalendarPage> createState() => _ObjectsCalendarPageState();
}

class _ObjectsCalendarPageState extends State<ObjectsCalendarPage> {
  final Map<DateTime, List<ObjectEvent>> events = {};

  List<Map<String, dynamic>> objects = [];

  Map<String, dynamic>? selectedObject;

  bool loading = true;

  DateTime focusedDay = DateTime.now();

  DateTime? selectedDay;

  CalendarFormat calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();

    loadObjects();
    loadEvents();
  }

  void onDayTap(DateTime day) {
    const double hourHeight = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final dayEvents = getEventsForDay(day);

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,

          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),

          child: Column(
            children: [
              /// Ручка
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// Дата
              Text(
                "${day.day}.${day.month}.${day.year}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 24 * hourHeight,

                    child: Stack(
                      children: [
                        /// Шкала времени
                        Column(
                          children: List.generate(24, (hour) {
                            return SizedBox(
                              height: hourHeight,

                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),

                                      child: Text(
                                        "${hour.toString().padLeft(2, '0')}:00",

                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),

                        /// События
                        ...List.generate(dayEvents.length, (index) {
                          final event = dayEvents[index];

                          final startMinutes =
                              event.start.hour * 60 + event.start.minute;

                          final endMinutes =
                              event.end.hour * 60 + event.end.minute;

                          final top = startMinutes * (hourHeight / 60);

                          final height =
                              (endMinutes - startMinutes).clamp(30, 10000) *
                              (hourHeight / 60);

                          int overlapIndex = 0;

                          for (int i = 0; i < index; i++) {
                            final other = dayEvents[i];

                            final otherStart =
                                other.start.hour * 60 + other.start.minute;

                            final otherEnd =
                                other.end.hour * 60 + other.end.minute;

                            if (startMinutes < otherEnd &&
                                endMinutes > otherStart) {
                              overlapIndex++;
                            }
                          }

                          final left = 70.0 + overlapIndex * 45;

                          return Positioned(
                            top: top,
                            left: left,
                            right: 15,

                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,

                                  builder: (_) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),

                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            color: getColor(event.importance),
                                          ),

                                          const SizedBox(width: 8),

                                          Expanded(child: Text(event.title)),
                                        ],
                                      ),

                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            "🕒 ${formatTime(event.start)}"
                                            " - "
                                            "${formatTime(event.end)}",
                                          ),

                                          const SizedBox(height: 8),

                                          Text("📍 ${event.place}"),
                                        ],
                                      ),

                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },

                                          child: const Text("Закрыть"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },

                              child: Container(
                                height: height,

                                padding: const EdgeInsets.all(8),

                                decoration: BoxDecoration(
                                  color: getColor(event.importance),

                                  borderRadius: BorderRadius.circular(12),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      event.title,

                                      maxLines: 2,

                                      overflow: TextOverflow.ellipsis,

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "${formatTime(event.start)}"
                                      " - "
                                      "${formatTime(event.end)}",

                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      event.place,

                                      maxLines: 1,

                                      overflow: TextOverflow.ellipsis,

                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (dayEvents.isEmpty)
                          const Positioned(
                            top: 150,
                            left: 0,
                            right: 0,

                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 50,
                                    color: Colors.grey,
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    "На этот день нет событий",

                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";
  }

  Color getColor(String importance) {
    switch (importance) {
      case "red":
        return Colors.red;

      case "black":
        return Colors.black87;

      default:
        return Colors.blue;
    }
  }

  /// ==========================
  /// ЗАГРУЗКА ОБЪЕКТОВ
  /// ==========================
  Future<void> loadObjects() async {
    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .get();

    final data = doc.data();

    if (data == null) return;

    setState(() {
      objects = (data['objects'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['type'] == "object")
          .toList();

      loading = false;
    });
  }

  /// ==========================
  /// ЗАГРУЗКА СОБЫТИЙ
  /// ==========================
  Future<void> loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('events')
        .get();

    final Map<DateTime, List<ObjectEvent>> newEvents = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['start'] == null || data['end'] == null) {
        continue;
      }

      final start = (data['start'] as Timestamp).toDate().toLocal();

      final end = (data['end'] as Timestamp).toDate().toLocal();

      final key = DateTime(start.year, start.month, start.day);

      newEvents.putIfAbsent(key, () => []);

      newEvents[key]!.add(
        ObjectEvent(
          id: doc.id,

          title: data['name'] ?? '',

          place: data['place'] ?? '',

          start: start,

          end: end,

          importance: data['importance'] ?? 'blue',
        ),
      );
    }

    /// Сортировка событий по времени
    for (final day in newEvents.keys) {
      newEvents[day]!.sort((a, b) => a.start.compareTo(b.start));
    }

    if (!mounted) return;

    setState(() {
      events
        ..clear()
        ..addAll(newEvents);
    });
  }

  /// ==========================
  /// СОБЫТИЯ ДЛЯ ВЫБРАННОГО ДНЯ
  /// ==========================
  List<ObjectEvent> getEventsForDay(DateTime day) {
    if (selectedObject == null) {
      return [];
    }

    final dayEvents = events[normalize(day)] ?? [];

    return dayEvents.where((event) {
      return event.place == selectedObject!['name'];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ThemeDataChoice.value == White_ThemeData
                ? const AssetImage('assets/images/seaback.jpg')
                : const AssetImage('assets/images/greyback.jpg'),
            fit: BoxFit.cover,
          ),
        ),

        child: Center(
          child: Container(
            width: 950,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white54),
            ),

            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      /// ==================
                      /// ШАПКА
                      /// ==================
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),

                          const Expanded(
                            child: Text(
                              "Календарь объектов",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.today),
                            onPressed: () {
                              setState(() {
                                focusedDay = DateTime.now();

                                selectedDay = DateTime.now();
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ==================
                      /// ВЫБОР ОБЪЕКТА
                      /// ==================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedObject,

                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.home_work),
                          ),

                          hint: const Text("Выберите объект"),

                          items: objects.map((obj) {
                            return DropdownMenuItem(
                              value: obj,

                              child: Text(obj['name'] ?? "Без названия"),
                            );
                          }).toList(),

                          onChanged: (value) {
                            setState(() {
                              selectedObject = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// ==================
                      /// ЕСЛИ ОБЪЕКТ НЕ ВЫБРАН
                      /// ==================
                      if (selectedObject == null)
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(30),

                              decoration: BoxDecoration(
                                color: Colors.white38,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.meeting_room, size: 70),

                                  SizedBox(height: 15),

                                  Text(
                                    "Выберите объект\nдля просмотра расписания",
                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      /// ==================
                      /// КАЛЕНДАРЬ
                      /// ==================
                      if (selectedObject != null)
                        Expanded(
                          child: TableCalendar<ObjectEvent>(
                            firstDay: DateTime.utc(2020, 1, 1),

                            lastDay: DateTime.utc(2035, 12, 31),

                            focusedDay: focusedDay,

                            calendarFormat: calendarFormat,

                            availableCalendarFormats: const {
                              CalendarFormat.week: "Месяц",
                            },

                            startingDayOfWeek: StartingDayOfWeek.monday,

                            rowHeight: calendarFormat == CalendarFormat.week
                                ? 430
                                : 75,

                            eventLoader: getEventsForDay,

                            onDaySelected: (selected, focused) {
                              setState(() {
                                selectedDay = selected;
                                focusedDay = focused;
                              });

                              onDayTap(selected);
                            },

                            calendarBuilders: CalendarBuilders(
                              /// ТОЧКИ СОБЫТИЙ
                              markerBuilder: (context, day, eventsList) {
                                if (eventsList.isEmpty) {
                                  return const SizedBox();
                                }

                                return Positioned(
                                  bottom: 3,

                                  child: Row(
                                    children: eventsList.take(4).map((e) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),

                                        width: 8,
                                        height: 8,

                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,

                                          color: getColor(e.importance),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },

                              /// ЯЧЕЙКА ДНЯ
                              defaultBuilder: (context, day, focused) {
                                final dayEvents = getEventsForDay(day);

                                return Container(
                                  margin: const EdgeInsets.all(3),

                                  padding: const EdgeInsets.all(4),

                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),

                                    color: isSameDay(selectedDay, day)
                                        ? Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.3)
                                        : Colors.white12,
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        "${day.day}",

                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: dayEvents.length,

                                          itemBuilder: (_, index) {
                                            final event = dayEvents[index];
                                            return GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: Text(event.title),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Объект: ${event.place}",
                                                        ),
                                                        Text(
                                                          "Время: "
                                                          "${formatTime(event.start)} - ${formatTime(event.end)}",
                                                        ),
                                                        Text(
                                                          "Важность: ${event.importance}",
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Закрыть",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getColor(
                                                    event.importance,
                                                  ).withOpacity(0.85),
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                                child: Text(
                                                  "${formatTime(event.start)} ${event.title}",
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
