import 'package:flutter/material.dart';
import 'TextFieldContainer.dart';


class InputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final ValueChanged<String> onChanged;

  const InputField({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextFormField(
          validator: (onChanged) => onChanged!.isEmpty ? 'Please enter a number between 1 to 20.' : null,
          onChanged: onChanged,
          cursorColor: Colors.teal,
          maxLength: 2,

          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.black
                )
            ),
            hintText: hintText,
            labelText: labelText,
            labelStyle: TextStyle(
                color: Colors.black
            ),
            hintStyle: TextStyle(
                color: Colors.grey
            ),
          ),
        ),

    );
  }
}