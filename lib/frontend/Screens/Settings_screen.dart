import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/widget.dart';
import 'package:avto/frontend/Screens/Location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

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

  List objects = [];
  List equipment = [];
  List furniture = [];

  String currentUserRole = "member";
  final TextEditingController calendarDescriptionController =
      TextEditingController();

  bool canEditCalendar = false;

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
    loadCalendarInfo();
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

  Future<void> saveCalendarDescription() async {
    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'calendarDescription': calendarDescriptionController.text});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Описание календаря сохранено")),
    );
  }

  Future<void> loadCalendarInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .get();

    final data = doc.data();

    if (data != null) {
      calendarDescriptionController.text = data['calendarDescription'] ?? '';
    }
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
  // ====================================
  // Добавление объектов
  // ====================================

  Future<void> _addObject(String type) async {
    latlng.LatLng? selectedLocation;
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final placesController = TextEditingController();
    final capacityController = TextEditingController();

    bool hasStage = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(type == "object" ? "Новый объект" : "Новый склад"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Название"),
                    ),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map),
                        label: Text(
                          selectedLocation == null
                              ? "Выбрать место на карте"
                              : "Точка выбрана",
                        ),
                        onPressed: () async {
                          final point = await Navigator.push<latlng.LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocationPickerPage(),
                            ),
                          );

                          if (point != null) {
                            setDialogState(() {
                              selectedLocation = point;
                            });
                          }
                        },
                      ),
                    ),

                    TextField(
                      controller: placesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Количество места кв м",
                      ),
                    ),

                    if (type == "object") ...[
                      TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Вместимость участников",
                        ),
                      ),

                      SwitchListTile(
                        title: const Text("Есть сцена"),
                        value: hasStage,
                        onChanged: (value) {
                          setDialogState(() {
                            hasStage = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Отмена"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("Создать"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final newItem = {
      "type": type,
      "name": nameController.text,
      "latitude": selectedLocation!.latitude,
      "longitude": selectedLocation!.longitude,

      if (type == "object") ...{
        "places": int.tryParse(placesController.text) ?? 0,
        "capacity": int.tryParse(capacityController.text) ?? 0,
        "hasStage": hasStage,
      },

      "equipment": [],
      "furniture": [],
    };

    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({
          "objects": FieldValue.arrayUnion([newItem]),
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
          if (data == null || !mounted) return;

          setState(() {
            nameController.text = data['name'] ?? '';
            calendarCode = data['code'] ?? '';
            selectedAvatar = data['avatar'] ?? 0;
            objects = List.from(data['objects'] ?? []);
            equipment = List.from(data['equipment'] ?? []);
            furniture = List.from(data['furniture'] ?? []);
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

  Widget _resourcesBlock() {
    final halls = objects.where((e) => e['type'] == 'object').toList();

    final warehouses = objects.where((e) => e['type'] == 'warehouse').toList();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            /// ОБЪЕКТЫ
            ExpansionTile(
              title: const Text(
                "Объекты",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canManageCalendar)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addObject("object"),
                    ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: halls.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Нет объектов"),
                      ),
                    ]
                  : halls.map<Widget>((obj) {
                      return Card(
                        color: Colors.white70,
                        child: ListTile(
                          leading: const Icon(Icons.meeting_room),
                          title: Text(obj['name'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  content: SizedBox(
                                    width: 400,
                                    height: 300,
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: latlng.LatLng(
                                          (obj['latitude'] as num).toDouble(),
                                          (obj['longitude'] as num).toDouble(),
                                        ),
                                        initialZoom: 15,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        ),

                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: latlng.LatLng(
                                                (obj['latitude'] as num)
                                                    .toDouble(),
                                                (obj['longitude'] as num)
                                                    .toDouble(),
                                              ),
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
            ),

            /// СКЛАДЫ
            ExpansionTile(
              title: const Text(
                "Склады",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canManageCalendar)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addObject("warehouse"),
                    ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: warehouses.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Нет складов"),
                      ),
                    ]
                  : warehouses.map<Widget>((obj) {
                      return Card(
                        color: Colors.white70,
                        child: ListTile(
                          leading: const Icon(Icons.warehouse),
                          title: Text(obj['name'] ?? ''),
                          subtitle: Text(obj['address'] ?? ''),
                        ),
                      );
                    }).toList(),
            ),

            /// ОБОРУДОВАНИЕ
            ExpansionTile(
              title: const Text(
                "Оборудование",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: equipment.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Нет оборудования"),
                      ),
                    ]
                  : equipment.map<Widget>((item) {
                      return Card(
                        color: Colors.white70,
                        child: ListTile(
                          leading: const Icon(Icons.speaker),
                          title: Text(item['name'] ?? ''),
                        ),
                      );
                    }).toList(),
            ),

            /// МЕБЕЛЬ
            ExpansionTile(
              title: const Text(
                "Мебель",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: furniture.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Нет мебели"),
                      ),
                    ]
                  : furniture.map<Widget>((item) {
                      return Card(
                        color: Colors.white70,
                        child: ListTile(
                          leading: const Icon(Icons.chair),
                          title: Text(item['name'] ?? ''),
                        ),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватар
            CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage(
                'assets/avatarsc/avatar$selectedAvatar.png',
              ),
            ),

            const SizedBox(height: 15),

            // Выбор аватаров
            _avatarSelector(),

            const SizedBox(height: 10),

            // Название календаря
            TextField(
              controller: nameController,
              readOnly: !canManageCalendar,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),

              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Название календаря",

                suffixIcon: canManageCalendar
                    ? IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveName,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard() {
    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(
              Icons.people,
              participants.length.toString(),
              "Участники",
            ),

            _statItem(
              Icons.location_city,
              objects.length.toString(),
              "Объекты",
            ),

            _statItem(Icons.speaker, equipment.length.toString(), "Оборуд."),

            _statItem(Icons.chair, furniture.length.toString(), "Мебель"),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String count, String title) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueGrey),

        const SizedBox(height: 5),

        Text(
          count,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _descriptionCard() {
    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description),
                SizedBox(width: 8),
                Text(
                  "Описание календаря",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 15),

            TextField(
              controller: calendarDescriptionController,
              readOnly: !canManageCalendar,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Добавьте ссылки, инструкции, контакты...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            if (canManageCalendar) ...[
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Сохранить"),
                  onPressed: saveCalendarDescription,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inviteCodeCard() {
    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.key),
                SizedBox(width: 8),
                Text(
                  "Код приглашения",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SelectableText(
              calendarCode,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Скопировать"),
              onPressed: _copyCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _participantsCard() {
    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people),
                SizedBox(width: 8),
                Text(
                  "Участники",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 110,

              child: participants.isEmpty
                  ? const Center(child: Text("Нет участников"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,

                      itemCount: participants.length,

                      itemBuilder: (context, index) {
                        final user = participants[index];

                        return Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 12),

                          child: Column(
                            children: [
                              GestureDetector(
                                onTap:
                                    currentUserRole == "admin" &&
                                        user["role"] != "admin"
                                    ? () => _showRoleSheet(user["uid"])
                                    : null,

                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundImage: AssetImage(
                                    "assets/avatarsp/avatar${user["avatar"]}.png",
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                user["name"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),

                              Text(
                                user["role"],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourcesCard() {
    final halls = objects.where((e) => e["type"] == "object").toList();
    final warehouses = objects.where((e) => e["type"] == "warehouse").toList();

    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2),
                SizedBox(width: 8),
                Text(
                  "Ресурсы календаря",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _resourceTile(
                  icon: Icons.meeting_room,
                  title: "Объекты",
                  count: halls.length,
                  onAdd: canManageCalendar ? () => _addObject("object") : null,
                  onTap: () => _showItems("Объекты", halls),
                ),

                _resourceTile(
                  icon: Icons.warehouse,
                  title: "Склады",
                  count: warehouses.length,
                  onAdd: canManageCalendar
                      ? () => _addObject("warehouse")
                      : null,
                  onTap: () => _showItems("Объекты", warehouses),
                ),

                _resourceTile(
                  icon: Icons.speaker,
                  title: "Оборудование",
                  count: equipment.length,
                ),

                _resourceTile(
                  icon: Icons.chair,
                  title: "Мебель",
                  count: furniture.length,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile({
    required IconData icon,
    required String title,
    required int count,
    VoidCallback? onAdd,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 35),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("$count шт."),
                ],
              ),
            ),

            if (onAdd != null)
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: onAdd,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItems(String title, List items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),

        content: SizedBox(
          width: 400,
          height: 300,
          child: items.isEmpty
              ? const Center(child: Text("Список пуст"))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(item["name"] ?? "Без названия"),
                      ),
                    );
                  },
                ),
        ),
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

  Widget _exitButton() {
    final bool isAdmin = currentUserRole == "admin";

    return Card(
      color: isAdmin ? const Color.fromARGB(180, 220, 80, 80) : Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isAdmin ? _deleteCalendar : _leaveCalendar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(
                isAdmin ? Icons.delete_forever_rounded : Icons.logout_rounded,
                size: 30,
                color: isAdmin ? Colors.white : Colors.black87,
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? "Удалить календарь" : "Выйти из календаря",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isAdmin
                          ? "Удаление удалит все события, участников и данные календаря"
                          : "Вы покинете этот календарь, но остальные участники останутся",
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdmin ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: isAdmin ? Colors.white70 : Colors.black45,
              ),
            ],
          ),
        ),
      ),
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
            width: 850,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(25),
            ),

            child: Column(
              children: [
                /// Верхняя панель
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),

                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    Expanded(
                      child: Text(
                        "Настройки календаря",
                        textAlign: TextAlign.center,

                        style: GoogleFonts.pacifico(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _headerCard(),

                        const SizedBox(height: 15),

                        _statsCard(),

                        const SizedBox(height: 15),

                        _descriptionCard(),

                        const SizedBox(height: 15),

                        if (canManageCalendar) _inviteCodeCard(),

                        const SizedBox(height: 15),

                        _participantsCard(),

                        const SizedBox(height: 15),

                        _resourcesCard(),

                        const SizedBox(height: 20),

                        _exitButton(),
                      ],
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
