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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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
            width: 600,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
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
                          "Профиль пользователя",
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

                SizedBox(height: 10),

                Text(
                  user?.email ?? "Нет email",
                  style: TextStyle(fontSize: 16),
                ),

                SizedBox(height: 10),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Имя",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save),
                      onPressed: _saveName,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Expanded(child: UserEventsWidget()),

                SizedBox(height: 10),

                SizedBox(
                  width: 600,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: Text("Выйти из аккаунта"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white60,
                    ),
                  ),
                ),

                SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
