import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swipe_gesture_recognizer/swipe_gesture_recognizer.dart';
import 'BluetoothConnection.dart';

enum action {
  ADD, REMOVE, PLACE
}

enum command {
  FORWARD, BACK, LEFT, RIGHT
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class GridArena extends StatefulWidget {
   @override
   _GridArenaState createState() => _GridArenaState();

 }
 
 class _GridArenaState extends State<GridArena> {

  int _columns = 10;
  int _rows = 15;

  List<int> _index = [];
  int _robot = -1;
  var _action;

  Border _border = Border();
  var _cards = new Map();

  static final clientID = 0;
  var connection  = BluetoothStateBroadcastWrapper.connection ;
  // var server;

  List<_Message> messages = List<_Message>.empty(growable: true);
  var _command;

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection!=null ? true : false);

  bool isDisconnecting = false;


  @override
  void initState() {
    super.initState();

    try{
      if (connection != null){
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

  Card rebuildCard (index, border) {
      return  Card(
        color: (_index.contains(index)) ? Colors.blueGrey : Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: Container(
            child: _robot == index?
            Icon( Icons.android,
                  color: Colors.deepOrange,) : null,
            decoration: BoxDecoration(
              border: Border()
            ),
            height: 100,
            width: 100,
          ),
        ),
      );
  }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Row(
         children: <Widget>[
           //Place robot
           IconButton(onPressed: () => {
              _action = action.PLACE
           }, icon: Icon(Icons.android_rounded)),
           //Place obstacle
           IconButton(onPressed: () => {
              _action = action.ADD
           }, icon: Icon(Icons.view_in_ar)),
           //Remove obstacle
           IconButton(onPressed: () => {
             _action = action.REMOVE
           }, icon: Icon(Icons.close))

         ],
       )),
         body: Padding(
           padding: const EdgeInsets.all(8.0),
           child: Container(
             // height: MediaQuery.of(context).size.height*.95,
             // width: MediaQuery.of(context).size.width*.7,
             child: GridView.count(
               childAspectRatio: 1,
               crossAxisCount: _columns,
               children: List.generate(_rows*_columns, (index) {
                 return InkWell(
                   onTap: () => {
                     setState (() {
                       print(index);
                       if (_action == action.ADD)
                          _index.add(index);
                       else if (_action == action.REMOVE)
                         _index.remove(index);
                       else if (_action == action.PLACE) {
                         _robot = index;
                       }
                     })
                   },
                   onLongPress: () => {


                   },
                   child: SwipeGestureRecognizer(
                   onSwipeUp: () => {
                   setState((){
                   _border = Border(
                   top: BorderSide(width: 5, color: Colors.red)
                   );
                   print(_border);
                   })

                   },


                   onSwipeDown: () => {
                   setState((){
                   _border = Border(
                   bottom: BorderSide(width: 5, color: Colors.red)
                   );
                   print(_border);
                   })

                   },

                   onSwipeLeft: () => {
                   setState((){
                   _border = Border(
                   left: BorderSide(width: 5, color: Colors.red)
                   );
                   print(_border);
                   })

                   },

                   onSwipeRight: () => {
                   setState((){
                   _border = Border(
                   right: BorderSide(width: 5, color: Colors.red)
                   );
                   print(_border);
                   }),
                   },

                   child: rebuildCard(index, _border)
                   ),
                 );
               }),

             ),
           ),
         ));
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

    print("dataString");
    print(dataString);

    setState(() {
      // messages.add(_Message(1, dataString));
      print(_robot);
      if(dataString == 'f'){
        if (_robot < _columns);
        else {
          _robot = (_robot-_columns);
          print(_robot);
        }
      }

      else if (dataString == 'b'){
        if (_robot >= (_columns*(_rows-1)));
        else {
          _robot = (_robot+_columns);
          print(_robot);
        }
      }

      else if (dataString == 'l'){
        if (_robot%_columns != 0) {
          _robot = _robot-1;
        }
      }

      else if (dataString == 'r'){
        if (_robot%_columns != _columns-1) {
          _robot = _robot+1;
        }
      }

    });
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text)));
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
 }
 