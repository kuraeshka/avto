import 'package:avto/Widget/Widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HelloWindow extends StatefulWidget {
  const HelloWindow({super.key});

  @override
  State<HelloWindow> createState() => _HelloWindowState();
}

class _HelloWindowState extends State<HelloWindow> {
  String Datanow = DateFormat.MMMM().format(DateTime.now());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/seaback.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Center(
                  child: Text(
                    "Давайте наведем порядок в расписании!",
                  
                    style: TextStyle(fontSize: 20,fontWeight: FontWeight.w400),
                  ),
                ),
              ],
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
        child: Container(height: 50.0),
        color: Theme.of(context).primaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Row_Calendar(context);
        },
        child: Icon(Icons.date_range),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
