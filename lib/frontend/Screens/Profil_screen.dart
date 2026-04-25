import 'package:avto/Widget/Widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilWindow extends StatefulWidget {
  const ProfilWindow({super.key});

  @override
  State<ProfilWindow> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ProfilWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Профиль пользователя")),
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 300,
                    width: 600,
                    child: Row(children: [Avatar_pro, info]),
                  ),
                ),
                SizedBox(height: 10),
                history,
                Spacer(),
                ElevatedButton(
                  onPressed: () async{

                    await FirebaseAuth.instance.signOut();

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (Route<dynamic> route) => false,
                    );
                    
                  },
                  child: Text("Выйти из аккаунта"),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
