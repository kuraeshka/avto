import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        .update({
      'name': nameController.text,
    });
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
        .update({
      'avatar': index,
    });
  }

  /// =========================================
  /// СМЕНА РОЛИ (С ЗАЩИТОЙ)
  /// =========================================
  Future<void> _changeRole(String uid, String role) async {
    final memberDoc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .doc(uid)
        .get();

    final targetRole = memberDoc.data()?['role'];

    /// ❌ НЕЛЬЗЯ МЕНЯТЬ АДМИНА
    if (targetRole == "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Нельзя изменить роль администратора"),
        ),
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
  /// BOTTOM SHEET РОЛЕЙ
  /// =========================================
  void _showRoleSheet(String uid) {
    showModalBottomSheet(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Скопировано: $calendarCode")),
    );
  }

  void _leaveCalendar() {
    Navigator.pop(context);
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/avatarsp/avatar${user['avatar']}.png',
                            ),
                          ),

                          title: Text(user['name']),

                          subtitle: Text("Роль: ${user['role']}"),

                          /// 🔒 КНОПКА ТОЛЬКО ДЛЯ НЕ-АДМИНОВ
                          trailing: (currentUserRole == "admin" &&
                                  user['role'] != "admin")
                              ? TextButton(
                                  onPressed: () =>
                                      _showRoleSheet(user['uid']),
                                  child: const Text("Сменить роль"),
                                )
                              : null,
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
          const Text(
            "Оборудование",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: equipment.length,
              itemBuilder: (_, i) {
                final item = equipment[i];

                return Card(
                  child: ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text("📍 ${item['place'] ?? ''}"),
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
        return GestureDetector(
          onTap: () => _setAvatar(index),
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
              backgroundImage: AssetImage(
                'assets/avatarsc/avatar$index.png',
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
      appBar: AppBar(
        title: const Text('Настройки календаря'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/seaback.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _avatarSelector(),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Название календаря",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveName,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        "Код: $calendarCode",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                    onPressed: _leaveCalendar,
                    child: const Text("Выйти из календаря"),
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