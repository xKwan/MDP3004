import 'package:flutter/material.dart';
import 'package:mdp3004/homepage.dart';

import './MainPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: MainPage(
    ));
  }
}
