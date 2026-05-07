import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserEventsWidget extends StatelessWidget {
  const UserEventsWidget({super.key});

  String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';

    return "$hour:$minute $ampm";
  }

  Future<Map<String, dynamic>> getCalendar(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(id)
        .get();

    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('events')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final performers = (data['performers'] as List?) ?? [];
          return performers.contains(userId);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text("Нет посещённых событий"),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data =
                filtered[i].data() as Map<String, dynamic>;

            final start =
                (data['start'] as Timestamp?)?.toDate();
            final end =
                (data['end'] as Timestamp?)?.toDate();

            final calendarId =
                filtered[i].reference.parent.parent!.id;

            return FutureBuilder<Map<String, dynamic>>(
              future: getCalendar(calendarId),
              builder: (context, snap) {
                final cal = snap.data ?? {};
                final name = cal['name'] ?? 'Без названия';
                final avatar = cal['avatar'] ?? 0;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(
                        'assets/avatarsc/avatar$avatar.png',
                      ),
                    ),

                    title: Text(data['name'] ?? ''),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 $name"),
                        if (start != null && end != null)
                          Text(
                            "⏰ ${formatTime(start)} - ${formatTime(end)}",
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}