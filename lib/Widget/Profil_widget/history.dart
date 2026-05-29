import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum SortType { time, alphabet, calendar }

class UserEventsWidget extends StatefulWidget {
  const UserEventsWidget({super.key});

  @override
  State<UserEventsWidget> createState() => _UserEventsWidgetState();
}

class _UserEventsWidgetState extends State<UserEventsWidget> {
  SortType selectedSort = SortType.time;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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

    return Column(
      children: [
        /// =========================
        /// ПОИСК + КНОПКИ
        /// =========================
        Padding(
          padding: const EdgeInsets.all(8),

          child: Row(
            children: [
              /// ПОИСК
              Expanded(
                child: TextField(
                  controller: searchController,

                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },

                  decoration: InputDecoration(
                    hintText: "Поиск посещений",

                    prefixIcon: const Icon(Icons.search),

                    filled: true,

                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// ПО ВРЕМЕНИ
              IconButton(
                tooltip: "По времени",

                onPressed: () {
                  setState(() {
                    selectedSort = SortType.time;
                  });
                },

                icon: Icon(
                  Icons.access_time,

                  color: selectedSort == SortType.time
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),

              /// ПО АЛФАВИТУ
              IconButton(
                tooltip: "По алфавиту",

                onPressed: () {
                  setState(() {
                    selectedSort = SortType.alphabet;
                  });
                },

                icon: Icon(
                  Icons.sort_by_alpha,

                  color: selectedSort == SortType.alphabet
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),

              /// ПО КАЛЕНДАРЯМ
              IconButton(
                tooltip: "По календарям",

                onPressed: () {
                  setState(() {
                    selectedSort = SortType.calendar;
                  });
                },

                icon: Icon(
                  Icons.calendar_month,

                  color: selectedSort == SortType.calendar
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),

        /// =========================
        /// СПИСОК СОБЫТИЙ
        /// =========================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('events')
                .snapshots(),

            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              /// =========================
              /// ФИЛЬТР
              /// =========================
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final performers = (data['performers'] as List?) ?? [];

                final eventName = (data['name'] ?? '').toString().toLowerCase();

                final matchesSearch = eventName.contains(
                  searchQuery.toLowerCase(),
                );

                return performers.contains(userId) && matchesSearch;
              }).toList();

              /// =========================
              /// СОРТИРОВКА
              /// =========================
              filtered.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;

                final dataB = b.data() as Map<String, dynamic>;

                switch (selectedSort) {
                  /// ПО ВРЕМЕНИ
                  case SortType.time:
                    final startA = (dataA['start'] as Timestamp).toDate();

                    final startB = (dataB['start'] as Timestamp).toDate();

                    return startB.compareTo(startA);

                  /// ПО АЛФАВИТУ
                  case SortType.alphabet:
                    return (dataA['name'] ?? '').toString().compareTo(
                      (dataB['name'] ?? '').toString(),
                    );

                  /// ПО КАЛЕНДАРЮ
                  case SortType.calendar:
                    final calA = a.reference.parent.parent?.id ?? '';

                    final calB = b.reference.parent.parent?.id ?? '';

                    return calA.compareTo(calB);
                }
              });

              if (filtered.isEmpty) {
                return const Center(child: Text("Нет посещённых событий"));
              }

              return ListView.builder(
                itemCount: filtered.length,

                itemBuilder: (_, i) {
                  final data = filtered[i].data() as Map<String, dynamic>;

                  final start = (data['start'] as Timestamp?)?.toDate();

                  final end = (data['end'] as Timestamp?)?.toDate();

                  final calendarId = filtered[i].reference.parent.parent!.id;

                  return FutureBuilder<Map<String, dynamic>>(
                    future: getCalendar(calendarId),

                    builder: (context, snap) {
                      final cal = snap.data ?? {};

                      final name = cal['name'] ?? 'Без названия';

                      final avatar = cal['avatar'] ?? 0;

                      return Card(
                        color: Colors.white70,

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

                              if (start != null && end != null) ...[
                                Text(
                                  "⏰ ${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}",
                                ),

                                Text(
                                  "⏰ ${formatTime(start)} - ${formatTime(end)}",
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
