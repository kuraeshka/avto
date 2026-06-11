import 'package:avto/Core/Theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilWindow extends StatefulWidget {
  const ProfilWindow({super.key});

  @override
  State<ProfilWindow> createState() => _ProfilWindowState();
}

class _ProfilWindowState extends State<ProfilWindow> {
  final user = FirebaseAuth.instance.currentUser;

  TextEditingController nameController = TextEditingController();

  int avatarIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Выход из аккаунта'),
            content: const Text('Вы действительно хотите выйти из аккаунта?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _loadUser() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      nameController.text = data['name'] ?? '';
      avatarIndex = data['avatar'] ?? 0;
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': 'Без имени',
        'avatar': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameController.text = 'Без имени';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveName() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': nameController.text,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Имя сохранено")));
  }

  Future<void> _setAvatar(int index) async {
    setState(() {
      avatarIndex = index;
    });

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'avatar': index,
    });
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
                color: avatarIndex == index ? Colors.blue : Colors.transparent,
                width: 3,
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage('assets/avatarsp/avatar$index.png'),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white38, width: 2),
            ),

            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// HEADER
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),

                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            "Мой профиль",

                            style: GoogleFonts.pacifico(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 50),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// ОСНОВНОЙ АВАТАР
                  CircleAvatar(
                    radius: 60,

                    backgroundImage: AssetImage(
                      "assets/avatarsp/avatar$avatarIndex.png",
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    nameController.text.isEmpty
                        ? "Пользователь"
                        : nameController.text,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    user?.email ?? "Нет email",

                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),

                  const SizedBox(height: 25),

                  /// ВЫБОР АВАТАРА
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Column(
                      children: [
                        const Text(
                          "Выберите аватар",

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        _avatarSelector(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// ИМЯ
                  TextField(
                    controller: nameController,

                    style: const TextStyle(color: Colors.black),

                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,

                      labelText: "Ваше имя",

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),

                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Colors.blue),

                        onPressed: _saveName,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// СОБЫТИЯ
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white30,

                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Row(
                            children: [
                              Icon(Icons.event, color: Colors.white),

                              SizedBox(width: 8),

                              Text(
                                "Мои ближайшие события",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          const Expanded(child: UserEventsWidget()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ВЫХОД
                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),

                      label: const Text(
                        "Выйти из аккаунта",

                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      onPressed: () async {
                        final confirm = await _showLogoutDialog();

                        if (!confirm) return;

                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
