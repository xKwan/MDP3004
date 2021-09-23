import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/GridArena.dart';
import 'BluetoothConnection.dart';
import 'Controls.dart';


class RobotUI extends StatefulWidget {

  @override
  _RobotUI createState() => new _RobotUI();
}

class _RobotUI extends State<RobotUI> {

  static get server => BluetoothStateBroadcastWrapper.connection;
  static BluetoothConnection? connection;
  static bool isConnecting = false;
  static bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;


  /*@override
  void initState() {
    super.initState();
    print("initState");
    try{
      if (connection != null){
        listenToStream();
        print("entered listen to stream");
      }

    } catch (e) {
      print(e);
    }
  }

  void getConnection() async {
    await Broadcast.setInstance(await BluetoothStateBroadcastWrapper.create(server.address));
    connection = BluetoothStateBroadcastWrapper.connection;
    setState(() {

    });
  }

  void listenToStream() {

    setState(() {
      isConnecting = false;
      isDisconnecting = false;
    });

    Broadcast.instance.btStateStream.listen(_onDataReceived).onDone(() {

      if (isDisconnecting) {
        print('Disconnecting locally!');
        // dispose();
      } else {
        print('Disconnected remotely!');
      }
      if (this.mounted) {
        setState(() {});
      }

    });
  }*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('MDP Android Group 15'),
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: <Widget>[
              Container(
                constraints: BoxConstraints(maxHeight: 150.0),
                child: Material(
                  color: Colors.grey[800],
                  child: TabBar(
                    indicatorColor: Colors.amberAccent[100],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.blue[200],
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.videogame_asset)),
                      Tab(icon: Icon(Icons.chat)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    GridArena(),
                    ControlsPage(),
                    Icon(Icons.directions_bike),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  /*void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);

    setState(() {
    });
  }*/

}
