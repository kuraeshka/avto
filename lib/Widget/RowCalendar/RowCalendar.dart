import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/RowCalendar/FormConnectCalendar.dart';
import 'package:avto/Widget/choice_Theme.dart';
import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void Row_Calendar(BuildContext context) {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  showModalBottomSheet(
    backgroundColor: Colors.white70,
    context: context,
    builder: (context) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Список календарей",
              style: GoogleFonts.pacifico(fontSize: 24, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('calendars')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: docs.map((doc) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('calendars')
                            .doc(doc.id)
                            .get(),
                        builder: (context, calendarSnap) {
                          if (!calendarSnap.hasData) {
                            return const SizedBox(
                              width: 160,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (!calendarSnap.data!.exists) {
                            return const SizedBox.shrink();
                          }
                          final cal =
                              calendarSnap.data!.data()
                                  as Map<String, dynamic>? ??
                              {};

                          final name = cal['name'] ?? '';
                          final avatar = cal['avatar'] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CoreScreen(calendarId: doc.id),
                                ),
                              );
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ThemeDataChoice.value == White_ThemeData
                                    ? Colors.blue
                                    : Colors.blueGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: AssetImage(
                                      'assets/avatarsc/avatar$avatar.png',
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            SizedBox(
              width: 100,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  FormConnectCalendar(context);
                },
                child: const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeDataChoice.value == White_ThemeData
                      ? Colors.blue
                      : Colors.blueGrey,
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
