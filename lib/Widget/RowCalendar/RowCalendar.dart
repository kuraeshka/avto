import 'package:avto/Widget/RowCalendar/FormAddCalendar.dart';
import 'package:flutter/material.dart';

void Row_Calendar(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 200,
        child: Row(
          children: [
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                FormAddCalendar(context);
              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}
