import 'package:avto/Widget/RowCalendar/FormConnectCalendar.dart';
import 'package:avto/frontend/Screens/Core_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void Row_Calendar(BuildContext context) {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("Список календарей"),
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
                      final data = doc.data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('calendars')
                            .doc(doc.id)
                            .get(),
                        builder: (context, calendarSnap) {
                          if (!calendarSnap.hasData) {
                            return const SizedBox(
                              width: 160,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
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
                                color: Colors.blue,
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

            ElevatedButton(
              onPressed: () {
                FormConnectCalendar(context);
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      );
    },
  );
}