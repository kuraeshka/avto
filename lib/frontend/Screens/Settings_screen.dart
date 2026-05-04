import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key, required this.calendarId});
  final String calendarId;

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  int selectedAvatar = 0;
  TextEditingController nameController = TextEditingController();

  String calendarCode = "";
  List participants = [];
  List equipment = [];

  @override
  @override
  void initState() {
    super.initState();
    _listenCalendar();
    _loadParticipants();
  }

  Future<void> _addEquipment() async {
    final nameController = TextEditingController();
    final placeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Добавить оборудование"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Наименование"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: placeController,
                decoration: InputDecoration(labelText: "Местоположение"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final place = placeController.text.trim();

                if (name.isEmpty) return;

                final newItem = {'name': name, 'place': place};

                final updatedList = List.from(equipment);
                updatedList.add(newItem);

                await FirebaseFirestore.instance
                    .collection('calendars')
                    .doc(widget.calendarId)
                    .update({'equipment': updatedList});

                Navigator.pop(context);
              },
              child: Text("Добавить"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadParticipants() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .collection('members')
        .get();

    final List<String> users = [];

    for (var doc in snapshot.docs) {
      users.add(doc.id); // пока просто UID
    }

    setState(() {
      participants = users;
    });
  }

  void _listenCalendar() {
    if (widget.calendarId.isEmpty) {
      print("ERROR: calendarId is empty");
      return;
    }
    FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .snapshots()
        .listen((doc) async {
          final data = doc.data();

          if (data == null) return;

          String code = data['code'] ?? '';

          /// 🔥 если нет кода — создаём
          if (code.isEmpty) {
            code = DateTime.now().millisecondsSinceEpoch.toString();

            await FirebaseFirestore.instance
                .collection('calendars')
                .doc(widget.calendarId)
                .update({'code': code});
          }

          setState(() {
            nameController.text = data['name'] ?? '';
            calendarCode = code;
            selectedAvatar = data['avatar'] ?? 0;
            equipment = data['equipment'] ?? [];
          });
        });
  }

  Future<void> _saveName() async {
    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'name': nameController.text});
  }

  Future<void> _setAvatar(int index) async {
    setState(() {
      selectedAvatar = index;
    });

    await FirebaseFirestore.instance
        .collection('calendars')
        .doc(widget.calendarId)
        .update({'avatar': index});
  }

  void _copyCode() {
    print("COPY CODE: $calendarCode");

    if (calendarCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Код ещё загружается...")));
      return;
    }

    Clipboard.setData(ClipboardData(text: calendarCode));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Скопировано: $calendarCode")));
  }

  void _leaveCalendar() {
    Navigator.pop(context);
  }

  Widget _avatarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return GestureDetector(
          onTap: () => _setAvatar(index),
          child: Container(
            margin: EdgeInsets.all(8),
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
        );
      }),
    );
  }

  Widget _listBlock(String title, List data) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                return ListTile(title: Text(data[i].toString()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentBlock() {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Оборудование",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: Icon(Icons.add), onPressed: _addEquipment),
            ],
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: equipment.length,
              itemBuilder: (_, i) {
                final item = equipment[i];

                return ListTile(
                  title: Text(item['name'] ?? ''),
                  subtitle: Text("📍 ${item['place'] ?? 'Не указано'}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки календаря')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/seaback.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 600,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                /// 🔥 АВАТАР
                _avatarSelector(),

                /// 🔥 ИМЯ
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Название календаря",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save),
                      onPressed: _saveName,
                    ),
                  ),
                ),

                SizedBox(height: 10),

                /// 🔥 КОД
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        "Код: $calendarCode",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.copy), onPressed: _copyCode),
                  ],
                ),

                SizedBox(height: 10),

                /// 🔥 СПИСКИ
                Row(
                  children: [
                    _listBlock("Участники", participants),
                    _equipmentBlock()
                  ],
                ),

                Spacer(),

                /// 🔥 ВЫХОД
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _leaveCalendar,
                    child: Text("Выйти из календаря"),
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
