import 'package:flutter/material.dart';
import 'package:mdp3004/DiscoveryPage.dart';
import 'package:mdp3004/SelectBondedDevicePage.dart';
import 'MainPage.dart';
import 'Robot_UI.dart';
import 'ChatPage.dart';
import 'GridArena.dart';

import 'DiscoveryPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


import './BluetoothDeviceListEntry.dart';

import 'BluetoothConnection.dart';

class HomePage extends StatefulWidget{
  //final BluetoothDevice server;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final PageStorageBucket bucket = PageStorageBucket();
  int _selectedIndex = 0;
/*  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }*/

  final List<Widget> _pages = [
    GridArena(),
    ChatPage(),
  ];

  void onTabTapped(int index) {

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ), //route to page based on index
      //body: MainPage(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // calls onTabTapped function
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.android),
            title: Text("Grid Arena"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            title: Text("Chat log"),
          ),
        ],
      ),
    );
  }
}