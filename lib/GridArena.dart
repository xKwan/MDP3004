import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mdp3004/helpers/CustomDialog.dart';
import 'package:swipe_gesture_recognizer/swipe_gesture_recognizer.dart';
import 'BluetoothConnection.dart';

enum action {
  UNKNOWN, ADD, REMOVE, PLACE, RESIZE, BORDER
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

  int _columns = 5;
  int _rows = 7;

  List<int> _index = [];
  int _robot = -1;
  var _action = action.UNKNOWN;

  Border _border = Border();
  var _cards = new Map();

  Map<int, Obstacle> obstacles = {};

  static final clientID = 0;
  var connection  = BluetoothStateBroadcastWrapper.connection ;
  // var server;

  List<_Message> messages = List<_Message>.empty(growable: true);

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

  Widget dragTarget(context, index) =>
      DragTarget<Obstacle>(
          builder: (context, candidateData, rejectedData) => Container(
              child:
              //Check if robot has been placed
              _robot == index?
              Icon( Icons.android,
                  color: Colors.deepOrange) :
              //Else check if obstacle has been placed
              _index.contains(index)?
              Text(obstacles[index]!.id.toString(),
                  style: TextStyle(color: Colors.white))
                  : null,
          ),
          onWillAccept: (data) => true,
          onAccept: (data) {
            setState(() {
              if(data.action == action.ADD){
                _index.add(index);
                data = Obstacle.updateIndex(data, index);
                obstacles.addAll({index: data});
                print(obstacles);
              }

            });
          }
      );

  Widget rebuildCard(BuildContext context, index) =>
        Card(
          color: (_index.contains(index)) ? Colors.blueGrey : Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          ),

            child: Container(
              decoration: BoxDecoration(
                  border: (
                    //Check if obstacle exists
                    _index.contains(index)) ?

                    //If exists, is the obstacle facing up?
                    obstacles[index]!.direction == "U" ? Border(
                    top: BorderSide(width: 5, color: Colors.red)
                    ):
                    //If exists, is the obstacle facing down?
                    obstacles[index]!.direction == "D" ? Border(
                    bottom: BorderSide(width: 5, color: Colors.red)
                    ):
                    //If exists, is the obstacle facing left?
                    obstacles[index]!.direction == "L" ? Border(
                    left: BorderSide(width: 5, color: Colors.red)
                    ):
                    //If exists, is the obstacle facing right?
                    obstacles[index]!.direction == "R" ? Border(
                    right: BorderSide(width: 5, color: Colors.red)
                    ):
                    //If does not exist or if direction not specified, return null
                    null : Border()
              ),
              height: 100,
              width: 100,
              child: Center(
                child: _index.contains(index)? Draggable<Obstacle>(
                  data: Obstacle.updateAction(obstacles[index]!, action.REMOVE),
                  child: dragTarget(context, index),
                  feedback: Material(child: Icon(Icons.view_in_ar, color: Colors.black) ),
                ): dragTarget(context, index),
            ),
          ),
        );


    Map<String, int> getCoordinates () {
      Map<String, int> cord = {"x": -1, "y": -1};
      if (_robot != -1){
        cord["x"] = _robot%_columns;
        cord["y"] = (_robot/_columns).floor();
      }
      return cord;
    }

   @override
   Widget build(BuildContext context) {
     int obstID = obstacles.entries.length;

     return Scaffold(
       appBar: AppBar(
         title: DragTarget<Obstacle>(
            builder: (context, candidateData, rejectedData) => Container(
             alignment: Alignment.center,
             child: Row(
              children: <Widget>[

                 //Change dimension of grid
                 IconButton(onPressed: () async => {
                   await CustomDialog.showDialog(context).then((gridVal) =>
                     setState(() {
                       print("Set");
                       _columns = gridVal["column"]!;
                       _rows = gridVal["row"]!;
                     })
                   ),

                  }, icon: Icon(Icons.apps)),

                 //Place robot
                 IconButton(onPressed: () => {
                   if(_action == action.PLACE)
                     _action = action.UNKNOWN
                   else
                    _action = action.PLACE
                 }, icon: Icon(Icons.android_rounded)),

                 //Place Obstacle
                 Draggable<Obstacle>(
                   data: new Obstacle(id: obstID++, action: action.ADD),
                   child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.view_in_ar)
                          ),
                   feedback: Material(child: Icon(Icons.view_in_ar, color: Colors.black) ),
                 ),

                Expanded(
                  flex: 5,
                  child: Container(
                    child: Text("("+
                      getCoordinates()["x"].toString()+" , "+
                          getCoordinates()["y"].toString()+")",
                      style: TextStyle(
                        fontSize: 25.0,
                      ),
                      // maxLines: 2,   // TRY THIS
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
             ),
            ),
             onWillAccept: (data) => true,
             onAccept: (data) {
               setState(() {
                 if(data.action == action.REMOVE){
                   _index.remove(data.index);
                   obstacles.remove(data.index);
                  print(obstacles);
                }
              });
            }
         ),
       ),
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
                       // if (_action == action.ADD)
                       //    _index.add(index);
                       // else if (_action == action.REMOVE)
                       //   _index.remove(index);
                       if (_action == action.PLACE) {
                         _robot = index;
                       }
                     })
                   },
                   child: GestureDetector(
                     onLongPressMoveUpdate: (updates) => {
                        setState(() {
                          if(updates.localOffsetFromOrigin.dx > 0 && updates.localOffsetFromOrigin.dy !> updates.localOffsetFromOrigin.dx){
                            Obstacle.updateDirection(obstacles[index]!, "D");
                          }
                          else if(updates.localOffsetFromOrigin.dx < 0 && updates.localOffsetFromOrigin.dy !> updates.localOffsetFromOrigin.dx){
                            Obstacle.updateDirection(obstacles[index]!, "L");
                          }
                          else if(updates.localOffsetFromOrigin.dy > 0){
                            Obstacle.updateDirection(obstacles[index]!, "R");
                          }
                          else if(updates.localOffsetFromOrigin.dy < 0){
                            Obstacle.updateDirection(obstacles[index]!, "U");
                          }
                        })

                     },

                     // onLongPress: () => {
                     //     onSwipeUp: () => {
                     //       setState((){
                     //         Obstacle.updateDirection(obstacles[index]!, "U");
                     //         print("up");
                     //       })
                     //
                     //     },
                     //
                     //
                     //     onSwipeDown: () => {
                     //       setState((){
                     //         Obstacle.updateDirection(obstacles[index]!, "D");
                     //         print("down");
                     //       })
                     //
                     //     },
                     //
                     //     onSwipeLeft: () => {
                     //       setState((){
                     //         Obstacle.updateDirection(obstacles[index]!, "L");
                     //         print("left");
                     //       })
                     //
                     //     },
                     //
                     //     onSwipeRight: () => {
                     //       setState((){
                     //         Obstacle.updateDirection(obstacles[index]!, "R");
                     //         print("right");
                     //       }),
                     //     },
                     //
                     // },
                     child: rebuildCard(context, index)
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

class Obstacle {
  var index;
  var id;
  var direction;
  var action;

  // get oid => this.id;
  // get dir => this.direction;

  static Obstacle updateAction(Obstacle obstacle, action) {
    obstacle.action = action;
    return obstacle;
  }

  static Obstacle updateIndex(Obstacle obstacle, index) {

    obstacle.index = index;
    return obstacle;
  }

  static Obstacle updateId(Obstacle obstacle, id) {

    obstacle.id = id;
    return obstacle;
  }

  static Obstacle updateDirection(Obstacle obstacle, dir) {

    obstacle.direction = dir;
    return obstacle;
  }

  Obstacle( {required this.id, this.index, this.direction, required this.action} );
}


 