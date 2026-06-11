import 'package:avto/Widget/Core_widget/On_event_tap.dart';
import 'package:avto/Widget/choice_Theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:avto/Core/Theme.dart';
import 'Core_screen.dart';

class ExecutorCalendarPage extends StatefulWidget {
  final String calendarId;
  final String userId;

  const ExecutorCalendarPage({
    super.key,
    required this.calendarId,
    required this.userId,
  });

  @override
  State<ExecutorCalendarPage> createState() => _ExecutorCalendarPageState();
}

class _ExecutorCalendarPageState extends State<ExecutorCalendarPage> {
  final Map<DateTime, List<Event>> events = {};

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('events')
        .get();

    final Map<DateTime, List<Event>> newEvents = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final performers = (data['performers'] is List)
          ? List<String>.from(
              (data['performers'] as List).expand((e) {
                if (e is List) return e;
                return [e];
              }),
            ).map((e) => e.toString()).toList()
          : <String>[];

      /// Показываем только мероприятия исполнителя
      if (!performers.contains(widget.userId)) {
        continue;
      }

      if (data['start'] == null || data['end'] == null) {
        continue;
      }

      final start = (data['start'] as Timestamp).toDate().toLocal();

      final end = (data['end'] as Timestamp).toDate().toLocal();

      final key = DateTime(start.year, start.month, start.day);

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
          performers: performers,
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
          checkList:
                    (data['checkList'] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    [], eventDescription: '',
          
        ),
      );
    }

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

  DateTime normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  List<Event> getEventsForDay(DateTime day) {
    return events[normalize(day)] ?? const [];
  }

  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

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

  @override
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
                        IconButton(
                          icon: const Icon(Icons.arrow_back),

                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),

                        const Spacer(),

                        const Text(
                          "Календарь исполнителя",

                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

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
                          CalendarFormat.week: 'Месяц',
                        },

                        eventLoader: getEventsForDay,

                        onDaySelected: (selectedDayValue, focusedDayValue) {
                          setState(() {
                            selectedDay = selectedDayValue;
                            focusedDay = focusedDayValue;
                          });
                        },

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
                            final dayEvents = getEventsForDay(day);

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
                                  Text(
                                    "${day.day}",

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,

                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

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
    );
  }
}
