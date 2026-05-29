import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({
    super.key,
    required this.calendarId,
    required this.currentUserId,
  });

  final String calendarId;
  final String currentUserId;

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  int selectedAvatar = 0;

  TextEditingController nameController = TextEditingController();

  String calendarCode = "";

  List<Map<String, dynamic>> participants = [];

  List equipment = [];

  String currentUserRole = "member";

  /// ✅ ПРАВА
  bool get canManageCalendar =>
      currentUserRole == "admin" || currentUserRole == "manager";

  bool get canEditEquipment =>
      currentUserRole == "admin" || currentUserRole == "manager";

  @override
  void initState() {
    super.initState();

    _listenCalendar();
    _loadCurrentUserRole();
    _loadParticipants();
  }

  /// =========================================
  /// РОЛЬ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ
  /// =========================================
  Future<void> _loadCurrentUserRole() async {
    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(widget.currentUserId)
        .get();

    setState(() {
      currentUserRole = doc.data()?['role'] ?? 'member';
    });
  }

  /// =========================================
  /// ДОБАВИТЬ ОБОРУДОВАНИЕ
  /// =========================================
  Future<void> _addEquipment() async {
    final nameController = TextEditingController();
    final placeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Добавить оборудование"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Название"),
              ),
              TextField(
                controller: placeController,
                decoration: const InputDecoration(labelText: "Место"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () async {
                final item = {
                  "name": nameController.text,
                  "place": placeController.text,
                };

                final updated = List.from(equipment)..add(item);

                await FirebaseFirestore.instance
                    .collection('calendars')
                    .doc(widget.calendarId)
                    .update({"equipment": updated});

                Navigator.pop(context);
              },
              child: const Text("Добавить"),
            ),
          ],
        );
      },
    );
  }

  /// =========================================
  /// РЕДАКТИРОВАТЬ ОБОРУДОВАНИЕ
  /// =========================================
  Future<void> _editEquipment(int index) async {
    final item = equipment[index];

    final nameController = TextEditingController(text: item['name']);

    final placeController = TextEditingController(text: item['place']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Редактировать"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController),
              TextField(controller: placeController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () async {
                equipment[index] = {
                  "name": nameController.text,
                  "place": placeController.text,
                };

                await FirebaseFirestore.instance
                    .collection('calendars')
                    .doc(widget.calendarId)
                    .update({"equipment": equipment});

                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  /// =========================================
  /// ЗАГРУЗКА УЧАСТНИКОВ
  /// =========================================
  Future<void> _loadParticipants() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .get();

    final List<Map<String, dynamic>> users = [];

    for (var doc in snapshot.docs) {
      final uid = doc.id;
      final memberData = doc.data();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = userDoc.data();

      users.add({
        'uid': uid,
        'name': data?['name'] ?? 'Без имени',
        'avatar': data?['avatar'] ?? 0,
        'role': memberData['role'] ?? 'observer',
      });
    }

    setState(() {
      participants = users;
    });
  }

  /// =========================================
  /// СЛУШАЕМ КАЛЕНДАРЬ
  /// =========================================
  void _listenCalendar() {
    FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .snapshots()
        .listen((doc) {
          final data = doc.data();

          if (data == null) return;

          setState(() {
            nameController.text = data['name'] ?? '';
            calendarCode = data['code'] ?? '';
            selectedAvatar = data['avatar'] ?? 0;
            equipment = data['equipment'] ?? [];
          });
        });
  }

  /// =========================================
  /// СОХРАНИТЬ НАЗВАНИЕ
  /// =========================================
  Future<void> _saveName() async {
    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'name': nameController.text});
  }

  /// =========================================
  /// СМЕНИТЬ АВАТАР
  /// =========================================
  Future<void> _setAvatar(int index) async {
    setState(() {
      selectedAvatar = index;
    });

    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'avatar': index});
  }

  /// =========================================
  /// СМЕНА РОЛИ
  /// =========================================
  Future<void> _changeRole(String uid, String role) async {
    final memberDoc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(uid)
        .get();

    final targetRole = memberDoc.data()?['role'];

    if (targetRole == "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Нельзя изменить роль администратора")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(uid)
        .update({'role': role});

    _loadParticipants();
  }

  /// =========================================
  /// ВЫБОР РОЛИ
  /// =========================================
  void _showRoleSheet(String uid) {
    showModalBottomSheet(
      backgroundColor: Colors.white70,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Наблюдатель"),
                onTap: () {
                  Navigator.pop(context);
                  _changeRole(uid, "observer");
                },
              ),
              ListTile(
                title: const Text("Исполнитель"),
                onTap: () {
                  Navigator.pop(context);
                  _changeRole(uid, "executor");
                },
              ),
              ListTile(
                title: const Text("Менеджер"),
                onTap: () {
                  Navigator.pop(context);
                  _changeRole(uid, "manager");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// =========================================
  /// КОПИРОВАТЬ КОД
  /// =========================================
  void _copyCode() {
    Clipboard.setData(ClipboardData(text: calendarCode));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Скопировано: $calendarCode")));
  }

  /// =========================================
  /// УДАЛИТЬ КАЛЕНДАРЬ
  /// =========================================
  Future<void> _deleteCalendar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Удаление календаря"),
          content: const Text("Вы уверены что хотите удалить календарь?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Удалить"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final calendarRef = FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId);

    /// Участники
    final members = await calendarRef.collection('members').get();

    /// Удаляем календарь у всех пользователей
    for (var member in members.docs) {
      final uid = member.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('calendars')
          .doc(widget.calendarId)
          .delete();
    }

    /// Удаляем events
    final events = await calendarRef.collection('events').get();

    for (var doc in events.docs) {
      await doc.reference.delete();
    }

    /// Удаляем members
    for (var doc in members.docs) {
      await doc.reference.delete();
    }

    /// Удаляем сам календарь
    await calendarRef.delete();

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  /// =========================================
  /// ВЫЙТИ ИЗ КАЛЕНДАРЯ
  /// =========================================
  Future<void> _leaveCalendar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Выход из календаря"),
          content: const Text("Вы уверены что хотите выйти из календаря?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Выйти"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final userId = widget.currentUserId;
    final calendarId = widget.calendarId;

    final batch = FirebaseFirestore.instance.batch();

    final memberRef = FirebaseFirestore.instance
        .collection('calendars')
        .doc(calendarId)
        .collection('members')
        .doc(userId);

    batch.delete(memberRef);

    final userCalendarRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('calendars')
        .doc(calendarId);

    batch.delete(userCalendarRef);

    await batch.commit();

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  /// =========================================
  /// СПИСОК УЧАСТНИКОВ
  /// =========================================
  Widget _listBlock(String title) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: participants.isEmpty
                ? const Center(child: Text("Нет участников"))
                : ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (_, i) {
                      final user = participants[i];

                      return Card(
                        color: Colors.white70,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(
                                  'assets/avatarsp/avatar${user['avatar']}.png',
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "Роль: ${user['role']}",
                                      style: const TextStyle(fontSize: 13),
                                    ),

                                    if (user['description'] != null &&
                                        user['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          user['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              if (currentUserRole == "admin" &&
                                  user['role'] != "admin")
                                TextButton(
                                  onPressed: () => _showRoleSheet(user['uid']),
                                  child: const Text("Роль"),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// =========================================
  /// ОБОРУДОВАНИЕ
  /// =========================================
  Widget _equipmentBlock() {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Оборудование",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              if (canEditEquipment)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addEquipment,
                ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: equipment.length,
              itemBuilder: (_, i) {
                final item = equipment[i];

                return Card(
                  color: Colors.white70,
                  child: ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text("📍 ${item['place'] ?? ''}"),

                    trailing: canEditEquipment ? const Icon(Icons.edit) : null,

                    onTap: canEditEquipment ? () => _editEquipment(i) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================
  /// АВАТАРЫ
  /// =========================================
  Widget _avatarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Opacity(
          opacity: canManageCalendar ? 1 : 0.4,
          child: GestureDetector(
            onTap: canManageCalendar ? () => _setAvatar(index) : null,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedAvatar == index
                      ? Colors.blue
                      : Colors.transparent,
                  width: 3,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/avatarsc/avatar$index.png'),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// =========================================
  /// UI
  /// =========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            width: 700,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(15),
            ),

            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          "Настройки календаря",
                          style: GoogleFonts.pacifico(
                            fontSize: 24,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 48),
                  ],
                ),

                _avatarSelector(),

                TextField(
                  controller: nameController,
                  readOnly: !canManageCalendar,

                  decoration: InputDecoration(
                    labelText: "Название календаря",

                    suffixIcon: canManageCalendar
                        ? IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _saveName,
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                if (canManageCalendar)
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          "Код: $calendarCode",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyCode,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                Expanded(
                  child: Row(
                    children: [
                      _listBlock("Участники"),

                      const SizedBox(width: 20),

                      _equipmentBlock(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentUserRole == "admin"
                          ? const Color.fromARGB(255, 208, 123, 123)
                          : Colors.white70,
                    ),

                    onPressed: currentUserRole == "admin"
                        ? _deleteCalendar
                        : _leaveCalendar,

                    child: Text(
                      currentUserRole == "admin"
                          ? "Удалить календарь"
                          : "Выйти из календаря",
                      style: GoogleFonts.pacifico(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
