import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final dynamic onSubmit;
  const RoundedButton({
    Key? key,
    required this.text,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(15),
      color: Colors.green,
      child: MaterialButton(
          padding: EdgeInsets.all(15.0),
          onPressed: onSubmit,
          child: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),

      ),
    );
  }
}
