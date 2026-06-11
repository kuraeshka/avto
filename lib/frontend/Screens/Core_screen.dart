import 'dart:async';

import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:avto/frontend/Screens/Celebration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Executor.dart';
import 'package:avto/frontend/Screens/object_calendar.dart';

class Event {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String place;
  final String calendarId;
  final double? latitude;
  final double? longitude;
  final String eventDescription;
  final List<String> performers;
  final List<String> equipment;
  final String importance;
  final List<Map<String, dynamic>> checkList;

  Event({
    required this.calendarId,
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.eventDescription,
    required this.place,
    this.latitude,
    this.longitude,
    required this.performers,
    required this.equipment,
    required this.importance,
    required this.checkList,
  });
}

class EventLayout {
  final int column;
  final int columns;

  EventLayout({required this.column, required this.columns});
}

class CoreScreen extends StatefulWidget {
  const CoreScreen({super.key, required this.calendarId});

  final String calendarId;

  @override
  State<CoreScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<CoreScreen> {
  final Map<DateTime, List<Event>> events = {};

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  StreamSubscription? _subscription;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  String currentUserRole = "observer";

  bool get canEdit =>
      currentUserRole == "admin" || currentUserRole == "manager";

  @override
  void initState() {
    super.initState();

    _loadRole();
    _listenEvents();
  }

  Map<String, EventLayout> calculateLayouts(List<Event> events) {
    final Map<String, EventLayout> result = {};

    List<List<Event>> columns = [];

    for (final event in events) {
      int columnIndex = 0;

      while (true) {
        if (columnIndex >= columns.length) {
          columns.add([]);
        }

        bool hasOverlap = columns[columnIndex].any((other) {
          return event.start.isBefore(other.end) &&
              event.end.isAfter(other.start);
        });

        if (!hasOverlap) {
          columns[columnIndex].add(event);
          break;
        }

        columnIndex++;
      }
    }

    int totalColumns = columns.length;

    for (int i = 0; i < columns.length; i++) {
      for (final event in columns[i]) {
        result[event.id] = EventLayout(column: i, columns: totalColumns);
      }
    }

    return result;
  }

  /// =========================================
  /// ЗАГРУЗКА РОЛИ
  /// =========================================
  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(uid)
        .get();

    setState(() {
      currentUserRole = doc.data()?['role'] ?? 'observer';
    });
  }

  /// =========================================
  /// СОБЫТИЯ
  /// =========================================
  void _listenEvents() {
    _subscription = FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('events')
        .snapshots()
        .listen((snapshot) {
          final Map<DateTime, List<Event>> newEvents = {};

          for (var doc in snapshot.docs) {
            final data = doc.data();

            if (data['start'] == null || data['end'] == null) continue;

            final start = (data['start'] as Timestamp).toDate().toLocal();

            final end = (data['end'] as Timestamp).toDate().toLocal();

            final key = _normalize(start);

            newEvents.putIfAbsent(key, () => []);

            newEvents[key]!.add(
              Event(
                calendarId: widget.calendarId,
                id: doc.id,
                title: data['name'] ?? '',
                start: start,
                end: end,
                place: data['place'] ?? '',
                latitude: (data['latitude'] as num?)?.toDouble(),
                longitude: (data['longitude'] as num?)?.toDouble(),

                performers: (data['performers'] is List)
                    ? List<String>.from(
                        (data['performers'] as List).expand((e) {
                          if (e is List) return e;
                          return [e];
                        }),
                      ).map((e) => e.toString()).toList()
                    : [],

                equipment: (data['equipment'] is List)
                    ? (data['equipment'] as List)
                          .map((e) {
                            if (e is Map && e['name'] != null) {
                              return e['name'].toString();
                            }
                            return e.toString();
                          })
                          .where((e) => e.trim().isNotEmpty)
                          .toList()
                    : [],

                importance: data['importance'] ?? 'blue',
                eventDescription: data['eventDescription']?.toString() ?? "",
                checkList:
                    (data['checkList'] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    [],
              ),
            );
          }

          /// сортировка
          for (var day in newEvents.keys) {
            newEvents[day]!.sort((a, b) => a.start.compareTo(b.start));
          }

          setState(() {
            events
              ..clear()
              ..addAll(newEvents);
          });
        });
  }

  /// =========================================
  /// ЦВЕТ СОБЫТИЯ
  /// =========================================
  Color getEventColor(String importance) {
    switch (importance) {
      case "red":
        return Colors.red;

      case "black":
        return Colors.black87;

      default:
        return Colors.blue;
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = _normalize(day);

    return events[key] ?? const [];
  }

  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  DateTime _normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  Widget _formatButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// =========================================
  /// ОТКРЫТИЕ ДНЯ
  /// =========================================
  void onDayTap(DateTime day) {
    const double hourHeight = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final dayEvents = _getEventsForDay(day);
        final layouts = calculateLayouts(dayEvents);
        final displayEvents = List<Event>.from(dayEvents.reversed);
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
                        ...List.generate(displayEvents.length, (index) {
                          final event = displayEvents[index];

                          final startMinutes =
                              event.start.hour * 60 + event.start.minute;

                          final endMinutes =
                              event.end.hour * 60 + event.end.minute;

                          final top = startMinutes * (hourHeight / 60);

                          final height =
                              (endMinutes - startMinutes).clamp(30, 10000) *
                              (hourHeight / 60);

                          final layout = layouts[event.id]!;

                          const double timelineWidth = 70;
                          const double padding = 20;
                          const double overlapOffset = 35;

                          final screenWidth = MediaQuery.of(context).size.width;

                          final availableWidth =
                              screenWidth - timelineWidth - padding;

                          // оставляем место для всех наложенных карточек
                          final totalShift =
                              (layout.columns - 1) * overlapOffset;

                          // ширина одинаковая для всех событий группы
                          final eventWidth = availableWidth - totalShift;

                          // сдвигаем каждую следующую карточку
                          final left =
                              timelineWidth + layout.column * overlapOffset;

                          return Positioned(
                            top: top,
                            left: left,
                            width: eventWidth,

                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);

                                Future.delayed(
                                  const Duration(milliseconds: 150),
                                  () {
                                    openEventDetails(event);
                                  },
                                );
                              },

                              child: Container(
                                height: height,

                                padding: const EdgeInsets.all(8),

                                decoration: BoxDecoration(
                                  color: getEventColor(
                                    event.importance,
                                  ).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),

                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxHeight < 50) {
                                      return Text(
                                        event.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          "${formatTime(event.start)} - ${formatTime(event.end)}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),

                                        if (constraints.maxHeight > 80)
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
                                    );
                                  },
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> openEventDetails(Event event) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('calendars')
          .doc(widget.calendarId)
          .get();

      final data = doc.data();

      if (data == null) {
        print("ОШИБКА: календарь не найден");
        return;
      }

      print("ДАННЫЕ КАЛЕНДАРЯ:");
      print(data);

      // Получаем список объектов
      final objectsRaw = data['objects'];

      print("OBJECTS:");
      print(objectsRaw);

      if (objectsRaw == null || objectsRaw is! List) {
        print("ОШИБКА: поле objects отсутствует или не является списком");
        return;
      }

      final List<Map<String, dynamic>> objects = objectsRaw
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      print("МЕСТО СОБЫТИЯ:");
      print(event.place);

      // Ищем объект по имени
      Map<String, dynamic> object = {};

      for (final obj in objects) {
        print("Сравниваем: ${obj['name']} <-> ${event.place}");

        if (obj['name'].toString().trim().toLowerCase() ==
            event.place.trim().toLowerCase()) {
          object = obj;
          break;
        }
      }

      print("НАЙДЕННЫЙ ОБЪЕКТ:");
      print(object);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(
            calendarId: widget.calendarId,
            name: event.title,
            id: event.id,
            eventDescription: event.eventDescription,
            objectName: object['name']?.toString() ?? event.place,

            // ссылка на фото Cloudinary
            objectImage: object['imageUrl']?.toString() ?? "",

            // оборудование
            equipment:
                (object['equipment'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],

            // мебель
            furniture:
                (object['furniture'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],

            // чеклист мероприятия
            checkList: event.checkList,

            canEdit: canEdit,
          ),
        ),
      );
    } catch (e, stack) {
      print("ОШИБКА openEventDetails:");
      print(e);
      print(stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ФОН
          Container(
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
                width: 900,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white24,

                  borderRadius: BorderRadius.circular(10),
                ),

                child: Column(
                  children: [
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.menu),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),

                          elevation: 8,

                          color: Colors.white,

                          position: PopupMenuPosition.under,

                          onSelected: (value) {
                            switch (value) {
                              case 'calendar_objects':
                                Navigator.pushNamed(
                                  context,
                                  '/objectsCalendar',
                                  arguments: {'calendarId': widget.calendarId},
                                );
                                break;

                              case 'calendar_executor':
                                Navigator.pushNamed(
                                  context,
                                  '/ExecutorCalendar',
                                  arguments: {
                                    'calendarId': widget.calendarId,
                                    'userId':
                                        FirebaseAuth.instance.currentUser?.uid,
                                  },
                                );

                                break;

                              case 'objects_info':
                                Navigator.pushNamed(
                                  context,
                                  '/ObjectsInfo',
                                  arguments: {'calendarId': widget.calendarId},
                                );
                                break;
                            }
                          },

                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'calendar_objects',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month),
                                  SizedBox(width: 12),
                                  Text('Календарь объектов'),
                                ],
                              ),
                            ),

                            const PopupMenuItem(
                              value: 'calendar_executor',
                              child: Row(
                                children: [
                                  Icon(Icons.person),
                                  SizedBox(width: 12),
                                  Text('Календарь исполнителя'),
                                ],
                              ),
                            ),

                            const PopupMenuItem(
                              value: 'objects_info',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline),
                                  SizedBox(width: 12),
                                  Text('Информация об объектах'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        /// Центр: переключатель Week / Month
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            children: [
                              _formatButton(
                                "Month",
                                _calendarFormat == CalendarFormat.month,
                                () {
                                  setState(
                                    () =>
                                        _calendarFormat = CalendarFormat.month,
                                  );
                                },
                              ),
                              _formatButton(
                                "Week",
                                _calendarFormat == CalendarFormat.week,
                                () {
                                  setState(
                                    () => _calendarFormat = CalendarFormat.week,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// Today — только иконка
                        IconButton(
                          tooltip: "Today",
                          icon: const Icon(Icons.today),
                          onPressed: () {
                            setState(() {
                              focusedDay = DateTime.now();
                              selectedDay = DateTime.now();
                            });
                          },
                        ),

                        const SizedBox(width: 12),

                        /// Профиль (прижат справа)
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/Profil');
                          },
                          icon: const Icon(Icons.person),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: TableCalendar<Event>(
                        firstDay: DateTime.utc(2020, 1, 1),

                        lastDay: DateTime.utc(2030, 12, 31),

                        focusedDay: focusedDay,

                        rowHeight: _calendarFormat == CalendarFormat.week
                            ? 440
                            : 75,

                        startingDayOfWeek: StartingDayOfWeek.monday,

                        calendarFormat: _calendarFormat,

                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Неделя',
                          CalendarFormat.week: 'Месяц',
                        },

                        onDaySelected: (selected, focused) {
                          selectedDay = selected;
                          focusedDay = focused;

                          setState(() {});

                          onDayTap(selected);
                        },

                        eventLoader: _getEventsForDay,

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, eventsList) {
                            if (eventsList.isEmpty) {
                              return const SizedBox();
                            }

                            return Positioned(
                              bottom: 2,

                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: eventsList.take(4).map((event) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),

                                    width: 7,
                                    height: 7,

                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      color: getEventColor(
                                        (event as Event).importance,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },

                          defaultBuilder: (context, day, focusedDay) {
                            final dayEvents = _getEventsForDay(day);
                            final layouts = calculateLayouts(dayEvents);

                            final isWeekView =
                                _calendarFormat == CalendarFormat.week;

                            return Container(
                              margin: const EdgeInsets.all(3),
                              padding: const EdgeInsets.all(4),

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),

                                color: isSameDay(selectedDay, day)
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.15),
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  /// ЧИСЛО
                                  Text(
                                    "${day.day}",

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  /// WEEK VIEW
                                  if (isWeekView)
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: dayEvents.length,

                                        itemBuilder: (context, index) {
                                          final event = dayEvents[index];

                                          return GestureDetector(
                                            onTap: () async {
                                              await onEventTap(
                                                event,
                                                context,
                                                widget.calendarId,
                                              );

                                              setState(() {});
                                            },

                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 4,
                                              ),

                                              padding: const EdgeInsets.all(4),

                                              decoration: BoxDecoration(
                                                color: getEventColor(
                                                  event.importance,
                                                ).withOpacity(0.85),

                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),

                                              child: Text(
                                                "${formatTime(event.start)} ${event.title}",

                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,

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

                                  /// MONTH VIEW
                                  if (!isWeekView) ...[
                                    ...dayEvents.take(2).map((event) {
                                      return Container(
                                        width: double.infinity,

                                        margin: const EdgeInsets.only(
                                          bottom: 0.5,
                                        ),

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 1,
                                        ),

                                        decoration: BoxDecoration(
                                          color: getEventColor(
                                            event.importance,
                                          ).withOpacity(0.85),

                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),

                                        child: Text(
                                          event.title,

                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,

                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            height: 1,
                                          ),
                                        ),
                                      );
                                    }),

                                    /// ЕСЛИ СОБЫТИЙ МНОГО
                                    if (dayEvents.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),

                                        child: Text(
                                          "+${dayEvents.length - 2}",

                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                  ],
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
        ],
      ),

      /// НИЖНЕЕ МЕНЮ
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,

        shape: const CircularNotchedRectangle(),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            IconButton(
              onPressed: () => Row_Calendar(context),

              icon: const Icon(Icons.date_range),
            ),

            IconButton(
              onPressed: () => ListPeople(context, widget.calendarId),

              icon: const Icon(Icons.group),
            ),

            const SizedBox(width: 40),

            /// SETTINGS
            IconButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/Settings', arguments: widget.calendarId),

              icon: const Icon(Icons.settings),
            ),

            IconButton(
              onPressed: () => choice(),

              icon: const Icon(Icons.brightness_3),
            ),
          ],
        ),
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        onPressed: canEdit
            ? () {
                CelebrationAdd(context, widget.calendarId);
              }
            : null,

        shape: const CircleBorder(),

        backgroundColor: canEdit ? Theme.of(context).primaryColor : Colors.grey,

        child: Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
