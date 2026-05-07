import 'dart:async';

import 'package:avto/Widget/Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Event({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.place,
    required this.performers,
    required this.equipment,
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

  @override
  void initState() {
    super.initState();
    _listenEvents();
  }

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

  void _onDayTap(DateTime day) {
    final dayEvents = _getEventsForDay(day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: SingleChildScrollView(
            child: SizedBox(
              height: 24 * 80,
              child: Stack(
                children: [
                  /// 🔥 ШКАЛА ВРЕМЕНИ
                  Column(
                    children: List.generate(24, (hour) {
                      return SizedBox(
                        height: 80,
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

                  /// 🔥 СОБЫТИЯ
                  ...dayEvents.map((event) {
                    final startMinutes =
                        event.start.hour * 60 + event.start.minute;

                    final endMinutes = event.end.hour * 60 + event.end.minute;

                    final top = startMinutes * (80 / 60);

                    final height =
                        (endMinutes - startMinutes).clamp(30, 10000) *
                        (80 / 60);

                    return Positioned(
                      top: top,
                      left: 70,
                      right: 10,
                      child: GestureDetector(
                        onTap: () =>
                            onEventTap(event, context, widget.calendarId),
                        child: Container(
                          height: height,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${event.title}\n${formatTime(event.start)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  /// 🔥 ЕСЛИ НЕТ СОБЫТИЙ
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/seaback.jpg'),
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

                child: TableCalendar<Event>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),

                  focusedDay: focusedDay,

                  rowHeight: 100,

                  startingDayOfWeek: StartingDayOfWeek.monday,

                  calendarFormat: _calendarFormat,

                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Месяц',
                  },

                  selectedDayPredicate: (day) {
                    return isSameDay(selectedDay, day);
                  },

                  onDaySelected: (selected, focused) {
                    selectedDay = selected;
                    focusedDay = focused;

                    setState(() {});

                    _onDayTap(selected);
                  },

                  eventLoader: _getEventsForDay,
                ),
              ),
            ),
          ),

          /// 👤 ПРОФИЛЬ
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/Profil');
              },
              icon: const Icon(Icons.person),
            ),
          ),
        ],
      ),

      /// 🔻 НИЖНЕЕ МЕНЮ
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

      /// ➕ ДОБАВИТЬ СОБЫТИЕ
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CelebrationAdd(context, widget.calendarId);
        },

        shape: const CircleBorder(),

        backgroundColor: Theme.of(context).primaryColor,

        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
