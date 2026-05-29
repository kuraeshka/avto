import 'package:avto/Core/Theme.dart';
import 'package:avto/Widget/Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegaWindow extends StatefulWidget {
  const RegaWindow({super.key});

  @override
  State<RegaWindow> createState() => _RegaWindowState();
}

class _RegaWindowState extends State<RegaWindow> {
  final TextEditingController loginController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController passwordAcceptController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ThemeDataChoice.value == White_ThemeData
                    ? const AssetImage('assets/images/seaback.jpg')
                    : const AssetImage('assets/images/greyback.jpg'),
                fit: BoxFit.cover,
              ),
            ),

            child: Center(
              child: SizedBox(
                width: 400,
                height: 350,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [
                    SizedBox(
                      width: 300,

                      child: Center(
                        child: Title(
                          color: Colors.white,

                          child: Text(
                            "Sign Up",

                            style: TextStyle(
                              fontSize: 30,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 300,

                      child: TextField(
                        controller: loginController,

                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Введите ваш Email',
                          prefixIcon: const Icon(Icons.email_outlined),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),

                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),

                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 300,

                      child: TextField(
                        controller: passwordController,
                        obscureText: true,

                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Введите ваш Password',
                          prefixIcon: const Icon(Icons.key),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),

                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),

                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 300,

                      child: TextField(
                        controller: passwordAcceptController,
                        obscureText: true,

                        decoration: InputDecoration(
                          labelText: 'Repeat password',
                          hintText: 'Введите ваш Password',
                          prefixIcon: const Icon(Icons.key),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),

                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),

                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 300,
                      height: 45,

                      child: ElevatedButton(
                        onPressed: () async {
                          if (passwordAcceptController.text !=
                              passwordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Пароли не совпадают"),
                              ),
                            );

                            return;
                          }

                          try {
                            final email = loginController.text.trim();

                            final password = passwordController.text.trim();

                            final userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            User? user = userCredential.user;

                            if (user == null) return;

                            /// Отправляем письмо
                            await user.sendEmailVerification();

                            final userId = user.uid;

                            /// Создаём пользователя
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .set({
                                  'email': email,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'avatar': 0,
                                  'name': '',
                                  'description': '',
                                });

                            if (!context.mounted) return;

                            /// Окно ожидания подтверждения
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) {
                                return const AlertDialog(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 20),
                                      Text(
                                        "Подтвердите почту.\nОжидание подтверждения...",
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );

                            bool verified = false;

                            while (!verified) {
                              await Future.delayed(const Duration(seconds: 3));

                              await FirebaseAuth.instance.currentUser?.reload();

                              user = FirebaseAuth.instance.currentUser;

                              verified = user?.emailVerified ?? false;
                            }

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Почта успешно подтверждена"),
                              ),
                            );

                            Navigator.of(context).pushNamedAndRemoveUntil(
                              "/Hello",
                              (route) => false,
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = 'Ошибка регистрации';

                            if (e.code == 'email-already-in-use') {
                              message = 'Пользователь уже существует';
                            } else if (e.code == 'weak-password') {
                              message = 'Слишком слабый пароль';
                            } else if (e.code == 'invalid-email') {
                              message = 'Неверный email';
                            }

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,

                          foregroundColor: Colors.white,

                          elevation: 0,
                        ),

                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
           Positioned(
              top: 20,
              left: 20,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/');
                },
                icon: const Icon(Icons.arrow_back),
                label: Text("Sign in"),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
