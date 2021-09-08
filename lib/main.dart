// @dart=2.9
import 'package:flutter/material.dart';
import 'package:mdp3004/GridArena.dart';

import './MainPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}
