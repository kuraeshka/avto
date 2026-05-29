import 'package:avto/Core/Theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:avto/Widget/Widget.dart';

class AuthenticationWindow extends StatefulWidget {
  const AuthenticationWindow({super.key});

  @override
  State<AuthenticationWindow> createState() => _AuthenticationWindowState();
}

class _AuthenticationWindowState extends State<AuthenticationWindow> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          image: DecorationImage(
            image: ThemeDataChoice.value == White_ThemeData
                ? const AssetImage('assets/images/seaback.jpg')
                : const AssetImage('assets/images/greyback.jpg'),
            fit: BoxFit.cover,
          ),
        ),

        child: Stack(
          children: [
            Center(
              child: Container(
                width: 300,
                height: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 30,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextField(
                      controller: loginController,

                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Введите ваш Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Введите ваш Password',
                        prefixIcon: Icon(Icons.key),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final email = loginController.text.trim();

                            final password = passwordController.text.trim();

                            final credential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            User? user = credential.user;

                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Ошибка авторизации"),
                                ),
                              );
                              return;
                            }

                            /// Обновляем пользователя
                            await user.reload();

                            user = FirebaseAuth.instance.currentUser;

                            /// Проверяем подтверждение почты
                            if (user == null || !user.emailVerified) {
                              await FirebaseAuth.instance.signOut();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Подтвердите почту перед входом",
                                  ),
                                ),
                              );

                              return;
                            }

                            if (!context.mounted) return;

                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/Hello',
                              (route) => false,
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = "Ошибка";

                            if (e.code == 'user-not-found') {
                              message = 'Пользователь не найден';
                            } else if (e.code == 'wrong-password') {
                              message = 'Неверный пароль';
                            } else if (e.code == 'invalid-email') {
                              message = 'Неверный email';
                            } else if (e.code == 'invalid-credential') {
                              message = 'Неверный логин или пароль';
                            }

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          "Sign in",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final email = loginController.text.trim();

                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Введите email")),
                          );
                          return;
                        }

                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Письмо для восстановления отправлено",
                              ),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          String message = "Ошибка";

                          if (e.code == 'user-not-found') {
                            message = "Пользователь не найден";
                          } else if (e.code == 'invalid-email') {
                            message = "Неверный email";
                          }

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      },
                      child: const Text("Forgot password?"),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/Rega');
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Sign Up'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
