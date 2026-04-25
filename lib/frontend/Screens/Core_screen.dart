import 'package:avto/Widget/Widget.dart';
import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';

class CoreScreen extends StatefulWidget {
  const CoreScreen({super.key, required this.calendarId});
  final String calendarId;

  

  @override
  
  State<CoreScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<CoreScreen> {
  late final EventsController controller;
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
  String currentMonth = months[DateTime.now().month - 1];
  final WeekParam myWeekParam = WeekParam(
    startOfWeekDay: 1,
    headerHeight: 45,
    headerDayBuilder: (int dayIndex) {
      const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      final index = (dayIndex - 1) % 7;
      return Center(
        child: Text(
          weekDays[index],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    },
  );
  String customHeaderDayText(int dayOfMonth) {
    const weekDays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    final index = dayOfMonth % 7; // приводит 7 → 0, 8 → 1 и т.д.
    return weekDays[index];
  }

  @override
  void initState() {
    super.initState();
    controller = EventsController(); // Создаём один раз
  }

  @override
  void dispose() {
    controller.dispose(); // Хороший тон – освобождать ресурсы
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentMonth, style: TextStyle(fontSize: 35, color: const Color.fromARGB(255, 65, 61, 61)),), centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed("/Profil");
            },
            icon: Icon(Icons.person),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/seaback.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            width: 900,
            child: EventsMonths(controller: controller, weekParam: myWeekParam),
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Row_Calendar(context);
              },
              icon: Icon(Icons.date_range),
            ),

            IconButton(
              onPressed: () {
                ListPeople(context);
              },
              icon: Icon(Icons.group),
            ),
            IconButton(onPressed: null, icon: Icon(null)),
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/Settings');
              },
              icon: Icon(Icons.settings),
            ),

            IconButton(
              onPressed: () {
                choice();
              },
              icon: Icon(Icons.brightness_3),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CelebrationAdd(context, controller);
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
