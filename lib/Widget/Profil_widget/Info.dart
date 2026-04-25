import 'package:flutter/material.dart';

var info = Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: TextButton(
                    onPressed: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("____________________"),
                        Text(
                          "Информация о пользователе",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Имя пользователя: ",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Пароль пользователя: ******",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Почта пользователя: ",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Изменить по нажатию',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        Text("____________________"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );