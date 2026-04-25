import 'package:avto/Widget/RowCalendar/FormConnectCalendar.dart';
import 'package:flutter/material.dart';

void FormAddCalendar(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Добавление календаря"),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.2,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Code',
                      hintText: 'Введите Code',
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
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        "/home",
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text("Подключение"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      FormConnectCalendar(context);
                    },
                    child: Text("Создать календарь"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
