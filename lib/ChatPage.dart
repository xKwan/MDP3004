import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/MainPage.dart';
import 'BluetoothConnection.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  // var connection = BluetoothStateBroadcastWrapper.connection;
  var broadcast;


  ChatPage({required this.server, this.broadcast});

  @override
  _ChatPage createState() => new _ChatPage(server, broadcast);
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  var connection  = BluetoothStateBroadcastWrapper.connection ;
  var broadcast;
  var server;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  set isConnected(connection) => isConnected = connection;

  bool isDisconnecting = false;

  _ChatPage(this.server, this.broadcast);


  @override
  void initState() {
    super.initState();

    print("chatinit");
    print(connection);
    if(connection == null){
      // BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      getConnection();


    //     print('Connected to the device');
    //
    //     connection = _connection;
    //     broadcast = _connection?.input?.asBroadcastStream();
    //
    //     setState(() {
    //       isConnecting = false;
    //       isDisconnecting = false;
    //     });
    //
    //
    //     connection?.input?.listen(_onDataReceived).onDone(() {
    //       // Example: Detect which side closed the connection
    //       // There should be `isDisconnecting` flag to show are we are (locally)
    //       // in middle of disconnecting process, should be set before calling
    //       // `dispose`, `finish` or `close`, which all causes to disconnect.
    //       // If we except the disconnection, `onDone` should be fired as result.
    //       // If we didn't except this (no flag set), it means closing by remote.
    //       if (isDisconnecting) {
    //         print('Disconnecting locally!');
    //         // dispose();
    //       } else {
    //         print('Disconnected remotely!');
    //       }
    //       if (this.mounted) {
    //         setState(() {});
    //       }
    //
    //     });
    //   }).catchError((error) {
    //     print('Cannot connect, exception occured');
    //     print(error);
    //   });
    // } else {
    //
    //   print("HELOO");
    // //     broadcast.listen(_onDataReceived).onDone(() {
    // //       // Example: Detect which side closed the connection
    // //       // There should be `isDisconnecting` flag to show are we are (locally)
    // //       // in middle of disconnecting process, should be set before calling
    // //       // `dispose`, `finish` or `close`, which all causes to disconnect.
    // //       // If we except the disconnection, `onDone` should be fired as result.
    // //       // If we didn't except this (no flag set), it means closing by remote.
    // //
    // //       isConnected = true;
    // //
    // //       if (isDisconnecting) {
    // //         print('Disconnecting locally!');
    // //         // dispose();
    // //       } else {
    // //         print('Disconnected remotely!');
    // //       }
    // //       if (this.mounted) {
    // //         setState(() {});
    // //       }
    // //
    // //     }).catchError((error) {
    // //   print('Cannot connect, exception occured');
    // //   print(error);
    // //   });
    } else {
      broadcast.btStateStream.listen(_onDataReceived).onDone(() {

        print("ondone");
        isConnected = true;

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

  }

  // @override
  void pushConnection() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    // if (isConnected) {
    //   isDisconnecting = true;
    //   connection?.dispose();
    //   connection = null;
    // }

    print("push");
    print(connection);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return MainPage(broadcast: broadcast);
        },
      ),
    );

    // super.dispose();
  }

  void getConnection() async {
    broadcast = await BluetoothStateBroadcastWrapper.create(widget.server.address);
    connection = BluetoothStateBroadcastWrapper.connection;
    print("HEADER");
    broadcast.btStateStream.listen(_onDataReceived).onDone(() {

      print("ondone");
      isConnected = true;

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
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => pushConnection(),
          ),
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
                  ? Text('Live chat with ' + serverName)
                  : Text('Chat log with ' + serverName))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                                ? 'Type your message...'
                                : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )
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
    // int index = buffer.indexOf(10);
    // if (~index != 0) {
    //   setState(() {
    //     messages.add(
    //       _Message(
    //         1,
    //         backspacesCounter > 0
    //             ? _messageBuffer.substring(
    //                 0, _messageBuffer.length - backspacesCounter)
    //             : _messageBuffer + dataString.substring(0, index),
    //       ),
    //     );
    //     _messageBuffer = dataString.substring(index);
    //   });
    // } else {
    //   _messageBuffer = (backspacesCounter > 0
    //       ? _messageBuffer.substring(
    //           0, _messageBuffer.length - backspacesCounter)
    //       : _messageBuffer + dataString);
    // }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
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

  // bool isConnected() {
  //   return connection != null && connection?.isConnected;
  // }
}
