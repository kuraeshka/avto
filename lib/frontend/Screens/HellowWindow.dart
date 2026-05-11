import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class HelloWindow extends StatefulWidget {
  const HelloWindow({super.key});

  @override
  State<HelloWindow> createState() => _HelloWindowState();
}

class _HelloWindowState extends State<HelloWindow> {
  String Datanow = DateFormat.MMMM().format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _checkUserName();
  }

  Future<void> _checkUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    final name = data?['name'];

    if (name == null || name.toString().trim().isEmpty) {
      Future.delayed(Duration.zero, () {
        _showNameDialog(user.uid);
      });
    }
  }

  void _showNameDialog(String uid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("Введите имя"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Ваше имя",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({
                      'name': name,
                    }, SetOptions(merge: true));

                Navigator.pop(context);
              },
              child: Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ThemeDataChoice.value == White_ThemeData
                    ? const AssetImage('assets/images/seaback.jpg')
                    : const AssetImage('assets/images/greyback.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Center(
                  child: Text(
                    "Давайте наведем порядок в расписании!",
                    style: GoogleFonts.pacifico(
                      fontSize: 28,
                      color: Colors.blueGrey,
                    ),
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