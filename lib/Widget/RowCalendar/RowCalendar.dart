import 'package:avto/Widget/RowCalendar/FormAddCalendar.dart';
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
        height: 250,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Список календарей"),
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

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoreScreen(calendarId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          width: 300,
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              data['name'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () {
                FormAddCalendar(context);
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      );
    },
  );
}
