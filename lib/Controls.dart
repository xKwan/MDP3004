import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/MainPage.dart';
import '../BluetoothConnection.dart';
// import 'BluetoothBroadcastState.dart';

class ControlsPage extends StatefulWidget {

  @override
  _ControlsPageState createState() => _ControlsPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}



class _ControlsPageState extends State<ControlsPage> with AutomaticKeepAliveClientMixin<ControlsPage>{
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
  bool get wantKeepAlive => true;

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
                      if (text == 'f'){
                        text = 'Forward';
                      }
                      if (text == 'tl'){
                        text = 'Turn Left';
                      }
                      if (text == 'tr'){
                        text = 'Turn Right';
                      }
                      if (text == 'r'){
                        text = 'Reverse';
                      }
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
                  _sendMessage('f');
                  Future.delayed(const Duration(milliseconds: 500), () {
                    var text = _encodeString('State: Moving forward...');
                    _onDataReceived(text);
                    var text2 = _encodeString('State: Ready');
                    _onDataReceived(text2);
                  });
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
                      _sendMessage('tl');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        var text = _encodeString('State: Rotating Anti-clockwise...');
                        _onDataReceived(text);
                        var text2 = _encodeString('State: Ready');
                        _onDataReceived(text2);
                      });
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
                      _sendMessage('tr');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        var text = _encodeString('State: Rotating Clockwise...');
                        _onDataReceived(text);
                        var text2 = _encodeString('State: Ready');
                        _onDataReceived(text2);
                      });
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

            SizedBox(height: 30.0),

            Container(
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Reverse');
                  _sendMessage('r');
                  Future.delayed(const Duration(milliseconds: 500), () {
                    var text = _encodeString('State: Reversing...');
                    _onDataReceived(text);
                    var text2 = _encodeString('State: Ready');
                    _onDataReceived(text2);
                  });
                },
                style: ElevatedButton.styleFrom(
                  //fixedSize: Size(240, 80),
                    primary: Colors.blue),
                icon: Icon(Icons.arrow_downward),
                label: Text('Reverse'),
              ),
            )
          ],
        ),
      ),
    );

  }

  _encodeString(var text) {
    return Uint8List.fromList(utf8.encode(text));
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

      print("Pagestorage: " + PageStorage.of(context).toString());
    });
    PageStorage.of(context)?.writeState(
      context,
      messages,
    );
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

        PageStorage.of(context)?.writeState(
          context,
          messages,
        );

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
