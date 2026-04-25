import 'package:flutter/material.dart';

var Avatar_set = Expanded(
  child: Container(
    alignment: Alignment.topCenter,
    height: 300,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(height: 30),
        CircleAvatar(
          radius: 75,
          backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
        ),
        SizedBox(height: 30),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: () {}, child: Icon(Icons.add)),
              ElevatedButton(onPressed: () {}, child: Icon(Icons.add)),
              ElevatedButton(onPressed: () {}, child: Icon(Icons.add)),
            ],
          ),
        ),
      ],
    ),
  ),
);
