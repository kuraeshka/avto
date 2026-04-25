import 'package:avto/Widget/ListPeopleInCalendar.dart';
import 'package:flutter/material.dart';

var history = Center(
            child: SizedBox(
              height: 300,
              width: 600,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text("______________________________________"),
                    Center(child: Text("История посещений ")),
                    Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: participants
                                    .map((name) => ListTile(title: Text(name)))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text("______________________________________"),
                  ],
                ),
              ),
            ),
          );