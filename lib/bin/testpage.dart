import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/MainPage.dart';
import '../BluetoothConnection.dart';
// import 'BluetoothBroadcastState.dart';

class TestPage extends StatefulWidget {

  // final BluetoothDevice server;
  // var connection = BluetoothStateBroadcastWrapper.connection;
  // var broadcast;

  // TestPage({required this.server});

  @override
  _TestPageState createState() => _TestPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}



class _TestPageState extends State<TestPage> {
  static final clientID = 0;
  var connection  = BluetoothStateBroadcastWrapper.connection ;
  var broadcast = Broadcast.instance;
  var server;
  bool isConnecting = true;
  bool get isConnected => (connection!=null ? true : false);
  // set isConnected(connection) => isConnected = connection;

  bool isDisconnecting = false;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final ScrollController listScrollController = new ScrollController();

  @override
  void initState() {
    super.initState();

    print("chatinit");
    print(connection);
    try{
      if (connection == null){
        print("not connected");

      } else {
        listenToStream();
      }

    } catch (e) {
      print(e);
    }

  }


  // void getConnection() async {
  //   await Broadcast.setInstance(await BluetoothStateBroadcastWrapper.create(widget.server.address));
  //   connection = BluetoothStateBroadcastWrapper.connection;
  //   listenToStream();
  //
  // }

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
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                    (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:_message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = "Name" ?? "Unknown";
    print('serverName is ' + serverName.toString());
    return Scaffold(
      appBar: AppBar(
          title: (Text('Controling $serverName')
          )),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 300,
              child: ListView(
                padding: const EdgeInsets.all(12.0),
                controller: listScrollController,
                children: list,
              ),
            ),

            SizedBox(height: 100.0),
            Container(
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Forward');
                  _sendMessage('Forward');
                },
                style: ElevatedButton.styleFrom(
                  //fixedSize: Size(240, 80),
                    primary: Colors.blue),
                icon: Icon(Icons.arrow_upward),
                label: Text('Forward'),
              ),
            ),
            SizedBox(height: 30.0),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      print('Left');
                      _sendMessage('Left');
                    },
                    style: ElevatedButton.styleFrom(
                      //fixedSize: Size(240, 80),
                        primary: Colors.blue),
                    icon: Icon(Icons.arrow_back),
                    label: Text('Left'),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      print('Right');
                      _sendMessage('Right');
                    },
                    style: ElevatedButton.styleFrom(
                      //fixedSize: Size(240, 80),
                        primary: Colors.blue),
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Right'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }

  void _onDataReceived(Uint8List data) {
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
      messages.add(_Message(1, dataString));
    });

  }

  void _sendMessage(String text) async {
    text = text.trim();
    print('Received button message $text');

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text)));
        await connection!.output.allSent;
        setState(() {
          messages.add(_Message(clientID,text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

}
