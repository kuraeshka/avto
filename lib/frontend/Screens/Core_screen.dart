import 'dart:async';
import 'package:avto/Widget/Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Event {
  final String title;
  final DateTime date;
  final String place;
  final List performers;
  final List equipment;

  Event({
    required this.title,
    required this.date,
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

  static List<String> months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  String get currentMonth => months[focusedDay.month - 1];

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
            final date = (data['date'] as Timestamp).toDate();

            final key = DateTime(date.year, date.month, date.day);

            newEvents.putIfAbsent(key, () => []);

            newEvents[key]!.add(
              Event(
                title: data['name'] ?? '',
                date: date,
                place: data['place'] ?? 'Не указано',
                performers: (data['performers'] ?? '')
                    .toString()
                    .split(',')
                    .where((e) => e.trim().isNotEmpty)
                    .toList(),

                equipment: (data['equipment'] ?? '')
                    .toString()
                    .split(',')
                    .where((e) => e.trim().isNotEmpty)
                    .toList(),
              ),
            );
          }

          setState(() {
            events
              ..clear()
              ..addAll(newEvents);
          });
        });
  }

  bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key].length != b[key].length) return false;
    }
    return true;
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? const [];
  }

  void _onEventTap(Event event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📅 Дата: ${event.date.toString().split(' ')[0]}"),
              SizedBox(height: 5),

              Text("📍 Место: ${event.place}"),
              SizedBox(height: 5),

              Text("👥 Участники:"),
              ...event.performers.map((p) => Text("• $p")),

              SizedBox(height: 5),

              Text("🛠 Оборудование:"),
              ...event.equipment.map((e) => Text("• $e")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  void _onDayTap(DateTime day) {
    final dayEvents = _getEventsForDay(day);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dayEvents.length,
          itemBuilder: (_, i) {
            final event = dayEvents[i];
            return ListTile(
              title: Text(event.title),
              onTap: () => _onEventTap(event),
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
                padding: EdgeInsets.all(16),
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
                    CalendarFormat.twoWeeks: '2 недели',
                    CalendarFormat.week: 'Неделя',
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (selected, focused) {
                    selectedDay = selected;
                    focusedDay = focused;
                    setState(() {});
                    _onDayTap(selected);
                  },
                  onPageChanged: (focused) {
                    focusedDay = focused;
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/Profil');
              },
              icon: Icon(Icons.person),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => Row_Calendar(context),
              icon: const Icon(Icons.date_range),
            ),
            IconButton(
              onPressed: () => ListPeople(context),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CelebrationAdd(context, widget.calendarId);
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
