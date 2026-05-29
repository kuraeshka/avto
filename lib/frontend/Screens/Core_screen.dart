import 'dart:async';

import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Event {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String place;
  final List<String> performers;
  final List<String> equipment;
  final String importance;

  Event({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.place,
    required this.performers,
    required this.equipment,
    required this.importance,
  });
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
                id: doc.id,
                title: data['name'] ?? '',
                start: start,
                end: end,
                place: data['place'] ?? 'Не указано',

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

  /// =========================================
  /// ОТКРЫТИЕ ДНЯ
  /// =========================================
  void _onDayTap(DateTime day) {
    const double hourHeight = 40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            /// ВСЕГДА АКТУАЛЬНЫЕ СОБЫТИЯ
            final dayEvents = _getEventsForDay(day);

            return Container(
              padding: const EdgeInsets.all(10.0),

              height: MediaQuery.of(context).size.height * 0.9,

              child: SingleChildScrollView(
                child: SizedBox(
                  height: 24 * hourHeight,

                  child: Stack(
                    children: [
                      /// ШКАЛА ВРЕМЕНИ
                      Column(
                        children: List.generate(24, (hour) {
                          return SizedBox(
                            height: hourHeight,

                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,

                                  child: Text(
                                    "$hour:00",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),

                                const Expanded(child: Divider()),
                              ],
                            ),
                          );
                        }),
                      ),

                      /// СОБЫТИЯ
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

                        /// ПОИСК КОНФЛИКТОВ
                        int overlapIndex = 0;

                        for (int i = 0; i < index; i++) {
                          final other = dayEvents[i];

                          final otherStart =
                              other.start.hour * 60 + other.start.minute;

                          final otherEnd =
                              other.end.hour * 60 + other.end.minute;

                          final isOverlap =
                              startMinutes < otherEnd &&
                              endMinutes > otherStart;

                          if (isOverlap) {
                            overlapIndex++;
                          }
                        }

                        /// СДВИГ
                        final double leftOffset = 70.0 + (overlapIndex * 40.0);

                        return Positioned(
                          top: top,
                          left: leftOffset,
                          right: 10,

                          child: GestureDetector(
                            onTap: () async {
                              await onEventTap(
                                event,
                                context,
                                widget.calendarId,
                              );

                              setModalState(() {});
                            },

                            child: Container(
                              height: height,

                              padding: const EdgeInsets.all(8),

                              decoration: BoxDecoration(
                                color: getEventColor(
                                  event.importance,
                                ).withOpacity(0.7),

                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Text(
                                "${event.title}\n${formatTime(event.start)}",

                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),

                      /// ЕСЛИ ПУСТО
                      if (dayEvents.isEmpty)
                        const Positioned(
                          top: 100,
                          left: 0,
                          right: 0,

                          child: Center(
                            child: Text(
                              "Нет событий",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              focusedDay = DateTime.now();
                              selectedDay = DateTime.now();
                            });
                          },

                          icon: const Icon(Icons.today),

                          label: const Text("Сегодня"),
                        ),

                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _calendarFormat =
                                  _calendarFormat == CalendarFormat.month
                                  ? CalendarFormat.week
                                  : CalendarFormat.month;
                            });
                          },

                          icon: Icon(
                            _calendarFormat == CalendarFormat.month
                                ? Icons.view_week
                                : Icons.calendar_month,
                          ),

                          label: Text(
                            _calendarFormat == CalendarFormat.month
                                ? "Неделя"
                                : "Месяц",
                          ),
                        ),
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

                          _onDayTap(selected);
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
                                          ),

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
