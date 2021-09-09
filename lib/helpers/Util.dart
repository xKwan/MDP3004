import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class Utils {
  static final List<Flushbar> flushBars = [];

  static void showSnackBar(
      BuildContext context, {
        required String text,
        required Color color,
      }) =>
      _show(
        context,
        Flushbar(
          //padding: EdgeInsets.all(24),
          messageText: Center(
              child: Text(
                text,
                style: TextStyle(color: Colors.black, fontSize: 18),
              )),
          duration: Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.BOTTOM,
          backgroundColor: color,
          barBlur: 1,
          borderRadius: BorderRadius.circular(10),
          animationDuration: Duration(microseconds: 0),
        ),
      );

  static Future _show(BuildContext context, Flushbar newFlushBar) async {
    await Future.wait(flushBars.map((flushBar) => flushBar.dismiss()).toList());
    flushBars.clear();

    newFlushBar.show(context);
    flushBars.add(newFlushBar);
  }
}