import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mdp3004/helpers/CustomDialog.dart';
import 'package:mdp3004/helpers/InputField.dart';
import 'BluetoothConnection.dart';
import 'helpers/RoundedButton.dart';
import 'helpers/Util.dart';

enum action { UNKNOWN, ADD, REMOVE, PLACE, RESIZE, BORDER }

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class GridArena extends StatefulWidget {
  @override
  _GridArenaState createState() => _GridArenaState();
}

class _GridArenaState extends State<GridArena>
    with AutomaticKeepAliveClientMixin<GridArena> {
  int _columns = 5;
  int _rows = 7;
  double _height = 0.5;
  double _updatedHeight = -1;

  List<int> _index = [];
  int robotIndex = -1;
  int robotY = 20;
  var _action = action.UNKNOWN;
  double robotAngle = 0;
  var robotCurrentDirection = "0";
  bool isStarted = false;
  String statusMessage = 'Robot Ready!';
  List<int> targetIDList = [];

  var imaginaryNorth = 0;
  var imaginarySouth = 0;
  var imaginaryEast = 0;
  var imaginaryWest = 0;

  Border _border = Border();
  var _cards = new Map();

  Map<int, Obstacle> obstacles = {};
  var data = "";

  String receivedText = "";
  String sentText = "";

  static final clientID = 0;
  var connection = BluetoothStateBroadcastWrapper.connection;

  // var server;

  List<_Message> messages = List<_Message>.empty(growable: true);

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;

  bool get isConnected => (connection != null ? true : false);
  bool isDisconnecting = false;

  final _formKey = GlobalKey<FormState>();
  int _updatedRow = -1;
  int _updatedColumn = -1;
  String error = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    try {
      if (connection != null) {
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

  // Widget dragTarget(context, index) => DragTarget<Obstacle>(
      // builder: (context, candidateData, rejectedData) => Container(
      //       child:
      //           //Check if robot has been placed
      //           robotIndex == index
      //               ? buildRotateRobot()
      //               :
      //               //Else check if obstacle has been placed
      //               _index.contains(index)
      //                   ? obstacles[index]!.isDiscovered
      //                       ? Expanded(
      //                           child: Image.asset('assets/id' +
      //                               obstacles[index]!.id.toString() +
      //                               '.png'))
      //                       : Text(obstacles[index]!.id.toString(),
      //                           style: TextStyle(color: Colors.white))
      //                   : null,
      //     ),
      // onWillAccept: (data) => true,
      // onAccept: (data) {
      //   setState(() {
      //     if (data.action == action.ADD) {
      //       _index.add(index);
      //       data = Obstacle.updateIndex(data, index);
      //       obstacles.addAll({index: data});
      //       print(obstacles);
      //
      //       _sendMessage("PC:ADD," +
      //           getObstacleCoordinates(obstacles[index]!)["x"].toString() +
      //           "," +
      //           getObstacleCoordinates(obstacles[index]!)["y"].toString());
      //     }
      //   });
      // });

  Widget buildRotateRobot() {
    if (robotCurrentDirection == "0") robotCurrentDirection = "N";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //Text(robotCurrentDirection),
        //Text(robotIndex.toString()),
        Transform.rotate(
          angle: robotAngle,
          //child: Expanded(
          child: FittedBox(
            child: Icon(
              Icons.arrow_upward_sharp,
              color: Colors.red,
              //size: 20,
            ),
          ),
          //),
        ),
      ],
    );
  }

  Widget rebuildCard(BuildContext context, index) => Card(
        color: (_index.contains(index)) ? Colors.blueGrey : Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
        ),
        child: Container(
          decoration: BoxDecoration(
              border: (
                      //Check if obstacle exists
                      _index.contains(index))
                  ?
                  //If exists, is the obstacle facing up?
                  obstacles[index]!.direction == "N"
                      ? Border(top: BorderSide(width: 5, color: Colors.red))
                      :
                      //If exists, is the obstacle facing down?
                      obstacles[index]!.direction == "S"
                          ? Border(
                              bottom: BorderSide(width: 5, color: Colors.red))
                          :
                          //If exists, is the obstacle facing left?
                          obstacles[index]!.direction == "W"
                              ? Border(
                                  left: BorderSide(width: 5, color: Colors.red))
                              :
                              //If exists, is the obstacle facing right?
                              obstacles[index]!.direction == "E"
                                  ? Border(
                                      right: BorderSide(
                                          width: 5, color: Colors.red))
                                  :
                                  //If does not exist or if direction not specified, return null
                                  null
                  : Border()),
          height: 100,
          width: 100,
          child: Center(
            child: Container(
                child:
                  //Check if robot has been placed
                  robotIndex == index
                  ? buildRotateRobot()
                      :
                  //Else check if obstacle has been placed
                        _index.contains(index)
                  ? obstacles[index]!.isDiscovered
                  ? Expanded(
                      child: Image.asset('assets/id' +
                      obstacles[index]!.id.toString() +
                      '.png'))
                          : Text(obstacles[index]!.id.toString(),
                      style: TextStyle(color: Colors.white))
                      : index % 4 == 0 ?
                            FittedBox(
                              child: Text(" " + (index % _columns).toString() + ", " +
                                  (19 - (index / _columns).floor()).toString() + " "),
                            ) : Text("")
                ),
          ),
              // onWillAccept: (data) => true,
              // onAccept: (data) {
              // setState(() {
              // if (data.action == action.ADD) {
              // _index.add(index);
              // data = Obstacle.updateIndex(data, index);
              // obstacles.addAll({index: data});
              // print(obstacles);
              //
              // _sendMessage("PC:ADD," +
              // getObstacleCoordinates(obstacles[index]!)["x"].toString() +
              // "," +
              // getObstacleCoordinates(obstacles[index]!)["y"].toString());
              // }
              // }
          // Center(
          //   child: _index.contains(index)
          //       ? Draggable<Obstacle>(
          //           data:
          //               Obstacle.updateAction(obstacles[index]!, action.REMOVE),
          //           child: dragTarget(context, index),
          //           feedback: Material(
          //               child: Icon(Icons.view_in_ar, color: Colors.black)),
          //         )
          //       : dragTarget(context, index),
          // ),
        ),
      );

  Map<String, int> getRobotCoordinates() {
    Map<String, int> cord = {"x": -1, "y": -1};
    if (robotIndex != -1) {
      cord["x"] = robotIndex % _columns;
      cord["y"] = (robotIndex / _columns).floor();
      robotY = (robotIndex / _columns).floor();
    }
    return cord;
  }

  Map<String, int> getObstacleCoordinates(Obstacle ob) {
    Map<String, int> cord = {"x": -1, "y": -1};
    if (ob.index != -1) {
      cord["x"] = ob.index % _columns;
      cord["y"] = (ob.index / _columns).floor();
    }
    return cord;
  }

  int getObstacleIndex(Map<String, int> cord) {
    int index = -1;

    if (!(cord["x"]! >= _columns) && !(cord["y"]! >= _rows)) {
      try {
        index = cord["x"]! + (cord["y"]! * _columns!);
      } catch (e) {
        print(e);
      }
    }

    return index;
  }

  @override
  Widget build(BuildContext context) {
    int obstID = obstacles.entries.length;
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  if (text == 'f') {
                    text = 'Forward';
                  }
                  if (text == 'tl') {
                    text = 'Turn Left';
                  }
                  if (text == 'tr') {
                    text = 'Turn Right';
                  }
                  if (text == 'r') {
                    text = 'Reverse';
                  }
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

    final serverName = "Name" ?? "Unknown";
    print('serverName is ' + serverName.toString());

    return WillPopScope(
      onWillPop: () async {
        bool willLeave = false;
        // show the confirm dialog
        await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text('Are you sure want to leave?'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          willLeave = true;
                          Navigator.of(context).pop();
                        },
                        child: Text('Yes')),
                    TextButton(
                        onPressed: () {
                          willLeave = false;
                          Navigator.of(context).pop();
                        },
                        child: Text('No'))
                  ],
                ));
        return willLeave;
      },
      child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.cyan,
            title:
            // DragTarget<Obstacle>(
            //     builder: (context, candidateData, rejectedData) =>
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: <Widget>[
                          //Change dimension of grid
                          // IconButton(
                          //     onPressed: () async => {
                          //           // changeGridDialog(context)
                          //           changeGridHeight(context)
                          //         },
                          //     icon: Icon(Icons.apps)),

                          //Place robot
                          IconButton(
                              onPressed: () => {
                                    if (_action == action.PLACE)
                                      _action = action.UNKNOWN
                                    else
                                      _action = action.PLACE
                                  },
                              icon: Icon(Icons.android_rounded)),

                          //Place Obstacle
                          IconButton(
                              onPressed: () => {
                                if (_action == action.ADD)
                                  _action = action.REMOVE
                                else if (_action == action.REMOVE)
                                  _action = action.UNKNOWN
                                else
                                  _action = action.ADD
                              },
                              icon: Icon(Icons.view_in_ar,
                                          color: Colors.white)),
                          // Draggable<Obstacle>(
                          //   data:
                          //       new Obstacle(id: obstID++, action: action.ADD),
                          //   child: Container(
                          //       decoration: BoxDecoration(
                          //           borderRadius: BorderRadius.circular(10)),
                          //       child: Icon(Icons.view_in_ar)),
                          //   feedback: Material(
                          //       child: Icon(Icons.view_in_ar,
                          //           color: Colors.black)),
                          // ),

                          FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20.0, 16.0, 0.0, 16.0),
                              child: Container(

                                child: Text(
                                  "Robot coordinates:\n"
                                          "(" +
                                      getRobotCoordinates()["x"].toString() +
                                      " , " +
                                      (19 - robotY).toString() +
                                      ")" +
                                      "  Index: " +
                                      robotIndex.toString() +
                                      "  DIR: " +
                                      robotCurrentDirection,
                                  /*style: TextStyle(
                                    //fontSize: 25.0,
                                    //fontWeight: FontWeight.bold
                                  ),*/
                                  // maxLines: 2,   // TRY THIS
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          /*Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(robotCurrentDirection),
                          ),*/

                          /*Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text("(" + robotIndex.toString() + ")"),
                          ),*/

                          FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20.0, 16.0, 0.0, 16.0),
                              child: Text(
                                "Out of bounds \n N: $imaginaryNorth | "
                                "S: $imaginarySouth | E: $imaginaryEast | W: $imaginaryWest",
                                textAlign: TextAlign.center,
                                //style: TextStyle(fontSize: 25),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                // onWillAccept: (data) => true,
                // onAccept: (data) {
                //   setState(() {
                //     if (data.action == action.REMOVE) {
                //       _sendMessage("PC:SUB," +
                //           getObstacleCoordinates(obstacles[data.index]!)["x"]
                //               .toString() +
                //           "," +
                //           getObstacleCoordinates(obstacles[data.index]!)["y"]
                //               .toString());
                //
                //       _index.remove(data.index);
                //       obstacles.remove(data.index);
                //       print(obstacles);
                //     }
                  // });
                // }),
            actions: [
              PopupMenuButton<int>(
                onSelected: (item) => onSelected(context, item),
                itemBuilder: (context) => [

                  PopupMenuItem<int>(
                      value: 0,
                      child: Text('Change dimensions of grid')
                  ),

                  PopupMenuItem<int>(
                      value: 1,
                      child: Text('Change height of grid')
                  ),

                ]
              )
            ],
          ),
          resizeToAvoidBottomInset: false,
          body: Container(
            child: Column(
              children: [
                Container(
                    //X-AXIS
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_columns, (index) {
                      return Padding(
                        padding: index == 0
                            ? EdgeInsets.only(top: 10, left: 450 / _rows)
                            : EdgeInsets.only(top: 10, left: 245 / _columns),
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            //"     " +
                                index.toString(),
                            //style: TextStyle(fontSize: 20 / (_columns / 7)),
                          ),
                        ),
                      );
                    }))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        //Y-AXIS
                        child: Column(
                            children: List.generate(_rows, (index) {
                      return Padding(
                        padding: index == 0
                            ? EdgeInsets.only(top: 200 / _columns, left: 5)
                            : EdgeInsets.only(left: 5, top: 245 / _rows),
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            (index).toString(),
                            //style: TextStyle(fontSize: 20 / (_columns / 7)),
                          ),
                        ),
                      );
                    }))),
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: MediaQuery.of(context).size.height * _height,
                          width: MediaQuery.of(context).size.width * .9,
                          child: GridView.count(
                            childAspectRatio: 1,
                            crossAxisCount: _columns,
                            children: List.generate(_rows * _columns, (index) {
                              return InkWell(
                                onTap: () => {
                                  setState(() {
                                    print(index);
                                    // if (_action == action.ADD)
                                    //    _index.add(index);
                                    // else if (_action == action.REMOVE)
                                    //   _index.remove(index);
                                    if (_action == action.ADD) {
                                      if(!_index.contains(index)){
                                        _index.add(index);
                                        Obstacle data = new Obstacle(id: obstID++, index: index);
                                        obstacles.addAll({index: data});
                                        print(obstacles);

                                        _sendMessage("PC:ADD," +
                                            getObstacleCoordinates(obstacles[index]!)["x"].toString() +
                                            "," +
                                            getObstacleCoordinates(obstacles[index]!)["y"].toString());
                                      }
                                    }
                                    else if (_action == action.REMOVE) {
                                      _sendMessage("PC:SUB," +
                                          getObstacleCoordinates(obstacles[index]!)["x"]
                                              .toString() +
                                          "," +
                                          getObstacleCoordinates(obstacles[index]!)["y"]
                                              .toString());

                                      _index.remove(index);
                                      obstacles.remove(index);
                                      print(obstacles);
                                    }
                                    else if (_action == action.PLACE) {
                                      robotIndex = index;
                                    }
                                  })
                                },
                                child: GestureDetector(
                                    onLongPressMoveUpdate: (updates) => {
                                          setState(() {
                                            if (updates.localOffsetFromOrigin
                                                        .dx >
                                                    0 &&
                                                updates.localOffsetFromOrigin
                                                        .dy! >
                                                    updates
                                                        .localOffsetFromOrigin
                                                        .dx) {
                                              Obstacle.updateDirection(
                                                  obstacles[index]!, "S");
                                            } else if (updates
                                                        .localOffsetFromOrigin
                                                        .dx <
                                                    0 &&
                                                updates.localOffsetFromOrigin
                                                        .dy! >
                                                    updates
                                                        .localOffsetFromOrigin
                                                        .dx) {
                                              Obstacle.updateDirection(
                                                  obstacles[index]!, "W");
                                            } else if (updates
                                                    .localOffsetFromOrigin.dy >
                                                0) {
                                              Obstacle.updateDirection(
                                                  obstacles[index]!, "E");
                                            } else if (updates
                                                    .localOffsetFromOrigin.dy <
                                                0) {
                                              Obstacle.updateDirection(
                                                  obstacles[index]!, "N");
                                            }
                                          })
                                        },
                                    onLongPressEnd: (details) => {
                                          obstacles[index]!.direction == "N"
                                              ? _sendMessage("PC:FACE," +
                                                  getObstacleCoordinates(obstacles[index]!)["x"]
                                                      .toString() +
                                                  "," +
                                                  getObstacleCoordinates(obstacles[index]!)["y"]
                                                      .toString() +
                                                  ",N")
                                              : obstacles[index]!.direction ==
                                                      "S"
                                                  ? _sendMessage("PC:FACE," +
                                                      getObstacleCoordinates(obstacles[index]!)["x"]
                                                          .toString() +
                                                      "," +
                                                      getObstacleCoordinates(obstacles[index]!)["y"]
                                                          .toString() +
                                                      ",S")
                                                  : obstacles[index]!.direction ==
                                                          "E"
                                                      ? _sendMessage("PC:FACE," +
                                                          getObstacleCoordinates(obstacles[index]!)["x"]
                                                              .toString() +
                                                          "," +
                                                          getObstacleCoordinates(obstacles[index]!)["y"]
                                                              .toString() +
                                                          ",E")
                                                      : obstacles[index]!
                                                                  .direction ==
                                                              "W"
                                                          ? _sendMessage("PC:FACE," +
                                                              getObstacleCoordinates(obstacles[index]!)["x"]
                                                                  .toString() +
                                                              "," +
                                                              getObstacleCoordinates(
                                                                      obstacles[index]!)["y"]
                                                                  .toString() +
                                                              ",W")
                                                          : null
                                        },
                                    child: rebuildCard(context, index)),
                              );
                            }),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Divider(thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      child: Text(
                        "Received: " + receivedText,
                      ),
                    ),
                    SizedBox(
                      child: Text(
                        "Sent: " + sentText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        child: Text(
                            "Started robot?: " + isStarted.toString()),
                      ),
                      SizedBox(
                        child: Text(
                            "Status Message: " + statusMessage),
                      ),
                    ]),
                Divider(height: 10, thickness: 2),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _sendMessage('PC:START');
                                      //createImaginaryObstacleWest();
                                      isStarted = true;
                                    },
                                    style: ElevatedButton.styleFrom(
                                        primary: Colors.green),
                                    icon: Icon(Icons.play_arrow),
                                    label: Text('Start'),
                                  ),
                                  VerticalDivider(width: 10.0, thickness: 2),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (isStarted == true) {
                                        confirmStopDialog(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        primary: Colors.red),
                                    icon: Icon(Icons.stop_circle),
                                    label: Text('Stop'),
                                  ),
                                ]),
                          ),
                          Divider(height: 30, thickness: 2),

                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print('Forward Left');
                                      forwardLeft();
                                      _sendMessage('tl');
                                      getSentText('Turn Left');
                                      /*var text = _encodeString('f');
                                       _onDataReceived(text);*/
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.lightBlueAccent),
                                    icon: Icon(
                                        Icons.keyboard_arrow_left_outlined),
                                    label: Text('Fwd Left'),
                                  ),
                                ),
                                VerticalDivider(width: 10.0, thickness: 2),
                                SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print('Forward');
                                      moveForward();
                                      _sendMessage('f');
                                      getSentText('Forward');
                                      /*var text = _encodeString('f');
                                      _onDataReceived(text);*/
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.amber[800]),
                                    icon: Icon(Icons.arrow_upward),
                                    label: Text('Forward'),
                                  ),
                                ),
                                VerticalDivider(width: 10.0, thickness: 2),
                                SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print('Forward Right');
                                      forwardRight();
                                      _sendMessage('tr');
                                      getSentText('Turn Right');
                                      /*var text = _encodeString('f');
                                       _onDataReceived(text);*/
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.lightBlueAccent),
                                    icon: Icon(
                                        Icons.keyboard_arrow_right_outlined),
                                    label: Text('Fwd Right'),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Divider(height: 30, thickness: 2),
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    rotateLeft();
                                    print('Rotate Left');
                                    /*_sendMessage('tl');
                                    var text = _encodeString('l');
                                    _onDataReceived(text);*/
                                  },
                                  style: ElevatedButton.styleFrom(
                                      //fixedSize: Size(240, 80),
                                      primary: Colors.amber[600]),
                                  icon: Icon(Icons.arrow_back),
                                  label: Text('Rotate Left'),
                                ),
                                //SizedBox(width: 10.0),
                                VerticalDivider(width: 10.0, thickness: 2),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    rotateRight();
                                    print('Rotate Right');
                                    /*_sendMessage('tr');
                                    var text = _encodeString('r');
                                    _onDataReceived(text);*/
                                  },
                                  style: ElevatedButton.styleFrom(
                                      //fixedSize: Size(240, 80),
                                      primary: Colors.amber[600]),
                                  icon: Icon(Icons.arrow_forward),
                                  label: Text('Rotate Right'),
                                ),
                              ],
                            ),
                          ),
                          //SizedBox(height: 30.0),
                          Divider(height: 30, thickness: 2),
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                /*SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print('Reverse Left');
                                      reverseLeft();
                                      */ /*_sendMessage('f');
                                       var text = _encodeString('f');
                                       _onDataReceived(text);*/ /*
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.blueAccent[800]),
                                    icon: Icon(Icons.subdirectory_arrow_left_rounded),
                                    label: Text('Rev Left'),
                                  ),
                                ),
                                VerticalDivider(width: 10.0, thickness: 2),*/
                                SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      moveReverse();
                                      print('Reverse');
                                      _sendMessage('r');
                                      var text = _encodeString('b');
                                      _onDataReceived(text);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.amber[800]),
                                    icon: Icon(Icons.arrow_downward),
                                    label: Text('Reverse'),
                                  ),
                                ),
                                /*VerticalDivider(width: 10.0, thickness: 2),
                                SizedBox(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print('Reverse Right');
                                      reverseRight();
                                      */ /*_sendMessage('f');
                                       var text = _encodeString('f');
                                       _onDataReceived(text);*/ /*
                                    },
                                    style: ElevatedButton.styleFrom(
                                        //fixedSize: Size(240, 80),
                                        primary: Colors.blueAccent[800]),
                                    icon:
                                        Icon(Icons.subdirectory_arrow_right_rounded),
                                    label: Text('Rev Right'),
                                  ),
                                ),*/
                              ],
                            ),
                          ),

                          /*ElevatedButton(
                               onPressed: () {
                                 setRobotLocation(4, 2, "W");
                               },
                               child: Text(
                                 "Set Robot Location",
                                 style: TextStyle(color: Colors.white),
                               )
                           ),*/
                          Divider(height: 30, thickness: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  _onDataReceived(Uint8List data) {
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
      getReceivedText(dataString);
      //messages.add(_Message(1, dataString));
      /*print(robotIndex);
      if(dataString == 'f'){
        if (robotIndex < _columns);
        else {
          robotIndex = (robotIndex-_columns);
          print(robotIndex);
        }
      }

      else if (dataString == 'b'){
        if (robotIndex >= (_columns*(_rows-1)));
        else {
          robotIndex = (robotIndex+_columns);
          print(robotIndex);
        }
      }

      else if (dataString == 'l'){
        if (robotIndex%_columns != 0) {
          robotIndex = robotIndex-1;
        }
      }

      else if (dataString == 'r'){
        if (robotIndex%_columns != _columns-1) {
          robotIndex = robotIndex+1;
        }
      }*/

/*
      DATASTRING FORMAT
      0                1  2   3   4
      TARGET/OBSTACLE, X, Y, ID, FACE

      */

      Map<String, int> cord = {};
      int index = -1;

      if (dataString.split(',')[0] == "ROBOT") {
        dataString = dataString.toUpperCase();
        print("Received ROBOT Command");
        setRobotLocation(int.parse(dataString.split(',')[1]),
            int.parse(dataString.split(',')[2]), dataString.split(',')[3]);
      }

      else if (dataString.split(',')[0].toUpperCase() == "TARGET") {
        print("Test command");
        int id = checkRobotCurrentLocation(dataString.split(',')[1]);
        targetIDList.add(id);
      }

      /*else if (dataString.split(',')[0] == "TARGET") {
        //TODO: GET INDEX
        cord["x"] = int.parse(dataString.split(',')[1]);
        cord["y"] = int.parse(dataString.split(',')[2]);

        index = getObstacleIndex(cord);

        print("INDEX: $index");
        if (index != -1) {
          if (obstacles[index] != null) {
            Obstacle data =
                Obstacle.updateId(obstacles[index]!, dataString.split(',')[3]);
            data = Obstacle.updateDiscovery(data, true);
            obstacles.update(index, (value) => data);
          } else {
            Obstacle data = new Obstacle(
                id: int.parse(dataString.split(',')[3]),
                index: index,
                action: action.UNKNOWN);

            data = Obstacle.updateDiscovery(data, true);

            _index.add(index);
            obstacles.addAll({index: data});
          }

          try {
            print("Try");
            Obstacle updatedObstacle = Obstacle.updateDirection(
                obstacles[index]!, dataString.split(',')[4].toString());
            obstacles.update(index, (value) => updatedObstacle);
          } catch (e) {
            print(e);
          }
        }
      }*/

      else {
        print("datastring is: $dataString");
        var char_list = dataString.split(',');
        print("char_list: $char_list");
        for(int i = 0; i < char_list.length; i++){
          print("$i char is: " + char_list[i].toString());
          _translateCommands(char_list[i]);
        }
      }
    });
    return dataString;
  }

  checkRobotCurrentLocation(id) {
    var x, y, dir;
    x = getRobotCoordinates()["x"];
    y = getRobotCoordinates()["y"];
    dir = robotCurrentDirection;

    if (robotCurrentDirection == "N") {
      y -= 3;
      dir = "S";
      if (y > 0 && y < _rows) {
        _updateObstacles(x, y, dir, id);
      }
    } else if (robotCurrentDirection == "S") {
      y += 3;
      dir = "N";
      if (y > 0 && y < _rows) {
        _updateObstacles(x, y, dir, id);
      }
    } else if (robotCurrentDirection == "E") {
      x += 3;
      dir = "W";
      if (x > 0 && x < _columns) {
        _updateObstacles(x, y, dir, id);
      }
    } else if (robotCurrentDirection == "W") {
      x -= 3;
      dir = "E";
      //_updateObstacles(x, y, dir, id);
      if (x > 0 && x < _columns) {
        _updateObstacles(x, y, dir, id);
      }
    }
  }

  /*_checkObstacleExists(x, y, dir, id){
    Map<String, int> cord = {}  ;
    int index = -1;
    cord["x"] = x;
    cord["y"] = y;
    int total = _rows*_columns;

    index = getObstacleIndex(cord);
    if(obstacles[index] != null){
      _updateObstacles(x, y, dir, id);
    }
  }*/

  _updateObstacles(x, y, dir, id) {
    int index = x + (_columns * y);
    setState(() {
      if (obstacles[index] != null) {
        Obstacle data = Obstacle.updateId(obstacles[index]!, id);
        data = Obstacle.updateDiscovery(data, true);
        obstacles.update(index, (value) => data);
      } else {
        Obstacle data = new Obstacle(
            id: int.parse(id), index: index);

        data = Obstacle.updateDiscovery(data, true);

        _index.add(index);
        obstacles.addAll({index: data});
      }

      try {
        print("Try");
        Obstacle updatedObstacle =
            Obstacle.updateDirection(obstacles[index]!, dir);
        obstacles.update(index, (value) => updatedObstacle);
      } catch (e) {
        print(e);
      }
    });
  }

  _translateCommands(dataString) async {
    //print("switch case:");
    try {
      switch (dataString) {
        case "e": // update obstacles' value
          int id = targetIDList[0];
          checkRobotCurrentLocation(id);
          if (targetIDList[0] != null){
            targetIDList.remove(targetIDList[0]);
          }
          break;

        case "w": // forward
          moveForward();

          print("received w");
          await Future.delayed(Duration(milliseconds: 540));
          statusMessage = "Robot Ready!";
          break;

        case "x": // reverse
          moveReverse();
          break;

        case "d": // turn right
          moveForward();
          await Future.delayed(Duration(milliseconds: 540));
          rotateRight();
          //await Future.delayed(Duration(milliseconds: 10000));
          await Future.delayed(Duration(milliseconds: 540));
          moveForward();
          await Future.delayed(Duration(milliseconds: 540));
          statusMessage = "Robot Ready!";
          break;

        case "a": // turn left
          moveForward();
          await Future.delayed(Duration(milliseconds: 540));
          rotateLeft();
          //await Future.delayed(Duration(milliseconds: 8000));
          await Future.delayed(Duration(milliseconds: 540));
          moveForward();
          await Future.delayed(Duration(milliseconds: 540));
          statusMessage = "Robot Ready!";
          break;

        case "1": // reverse 20cm
          moveReverse();
          await Future.delayed(Duration(milliseconds: 540));
          moveReverse();
          statusMessage = "Robot Ready!";
          break;
      }

      if (dataString == "0") {
        dataString = "10";
      }
      if (int.parse(dataString!) > 1 && int.parse(dataString!) < 11) {
        for (int i = 1; i <= int.parse(dataString!); i++) {
          moveForward();
          //await Future.delayed(Duration(milliseconds: 540));
        }
      }
    } catch (e) {
      print("error parsing received message");
    }
  }

  _encodeString(var text) {
    return Uint8List.fromList(utf8.encode(text));
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text)));
        await connection!.output.allSent;

        if (mounted) {
          setState(() {
            getSentText(text);
            messages.add(_Message(clientID, text));
          });
        }

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

  getSentText(text) {
    setState(() {
      sentText = text;
    });
    return sentText;
  }

  getReceivedText(text) {
    setState(() {
      receivedText = text;
    });
    return receivedText;
  }

  //North
  //if robot go out of bounds, generate extra row and col
  //"imaginary" grids that not supposed to exist
  createImaginaryNorthGrid() {
    imaginaryNorth += 1;
    createImaginaryObstacleNorth();
    _rows += 1;
    _columns += 1;
  }

  //move robot back on real grid
  //if on real grid, update index
  removeImaginaryNorthGrid() {
    imaginaryNorth -= 1;
    removeImaginaryObstacleNorth();
    _rows -= 1;
    _columns -= 1;
  }

  createImaginaryObstacleNorth() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex =
            imaginaryX + ((_columns + 1) * imaginaryY) + (_columns + 1);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  removeImaginaryObstacleNorth() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        print("Item " + (i + 1).toString());
        print("Number is:");
        print(_index[0]);

        print(obstacles[_index[0]]);

        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex =
            imaginaryX + ((_columns - 1) * imaginaryY) - (_columns - 1);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  //North

  // West
  createImaginaryWestGrid() {
    var imaginaryX;
    var imaginaryY;

    setState(() {
      imaginaryWest += 1;
      imaginaryX = (getRobotCoordinates()["x"]!)!;
      imaginaryY = (getRobotCoordinates()["y"]!)!;
      createImaginaryObstacleWest();
      _rows += 1;
      _columns += 1;
      robotIndex = (imaginaryX + ((_columns) * imaginaryY));
    });
  }

  removeImaginaryWestGrid() {
    var imaginaryX;
    var imaginaryY;

    imaginaryWest -= 1;
    imaginaryX = (getRobotCoordinates()["x"]!)!;
    imaginaryY = (getRobotCoordinates()["y"]!)!;
    removeImaginaryObstacleWest();
    _rows -= 1;
    _columns -= 1;
    robotIndex = (imaginaryX + ((_columns) * imaginaryY));
  }

  createImaginaryObstacleWest() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns + 1) * imaginaryY) + 1;

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  removeImaginaryObstacleWest() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        print("Item " + (i + 1).toString());
        print("Number is:");
        print(_index[0]);

        print(obstacles[_index[0]]);

        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns - 1) * imaginaryY) - 1;

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  // West

  // East
  createImaginaryEastGrid() {
    var imaginaryX;
    var imaginaryY;

    setState(() {
      imaginaryEast += 1;
      imaginaryX = (getRobotCoordinates()["x"]!)!;
      imaginaryY = (getRobotCoordinates()["y"]!)!;
      createImaginaryObstacleEast();
      _rows += 1;
      _columns += 1;
      robotIndex = (imaginaryX + ((_columns) * imaginaryY)) + 1;
    });
  }

  removeImaginaryEastGrid() {
    var imaginaryX;
    var imaginaryY;

    imaginaryEast -= 1;
    imaginaryX = (getRobotCoordinates()["x"]!)!;
    imaginaryY = (getRobotCoordinates()["y"]!)!;
    removeImaginaryObstacleEast();
    _rows -= 1;
    _columns -= 1;
    robotIndex = (imaginaryX + ((_columns) * imaginaryY));
    robotIndex = robotIndex - 1;
  }

  createImaginaryObstacleEast() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns + 1) * imaginaryY);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  removeImaginaryObstacleEast() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        print("Item " + (i + 1).toString());
        print("Number is:");
        print(_index[0]);

        print(obstacles[_index[0]]);

        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns - 1) * imaginaryY);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  //East

  //South
  createImaginarySouthGrid() {
    var imaginaryX;
    var imaginaryY;

    setState(() {
      imaginarySouth += 1;
      imaginaryX = (getRobotCoordinates()["x"]!)!;
      imaginaryY = (getRobotCoordinates()["y"]!)!;
      createImaginaryObstacleSouth();
      _rows += 1;
      _columns += 1;
      robotIndex = (imaginaryX + ((_columns) * imaginaryY));
      robotIndex = (robotIndex + _columns);
    });
  }

  removeImaginarySouthGrid() {
    var imaginaryX;
    var imaginaryY;

    imaginarySouth -= 1;
    imaginaryX = (getRobotCoordinates()["x"]!)!;
    imaginaryY = (getRobotCoordinates()["y"]!)!;
    removeImaginaryObstacleSouth();
    _rows -= 1;
    _columns -= 1;
    robotIndex = (imaginaryX + ((_columns) * imaginaryY));
  }

  createImaginaryObstacleSouth() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns + 1) * imaginaryY);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  removeImaginaryObstacleSouth() {
    Obstacle data;
    var imaginaryX;
    var imaginaryY;

    setState(() {
      print("Preserving obstacles' location");
      print(obstacles.length);
      for (int i = 0; i < _index.length; i++) {
        print("Item " + (i + 1).toString());
        print("Number is:");
        print(_index[0]);

        print(obstacles[_index[0]]);

        imaginaryY = _index[0] ~/ _rows;
        imaginaryX = _index[0] % _columns;

        int _updatedIndex = imaginaryX + ((_columns - 1) * imaginaryY);

        data = Obstacle.updateIndex(obstacles[_index[0]]!, _updatedIndex);
        obstacles.remove(obstacles[_index[0]]);
        obstacles.addAll({_updatedIndex: data});

        _index.remove(_index[0]);
        print(_updatedIndex);
        _index.add(_updatedIndex);
      }
    });
  }

  //South

  moveForward() {
    setState(() {
      statusMessage = "Moving Forward...";

      if (robotCurrentDirection == "N") {
        if (robotIndex < _columns) {
          createImaginaryNorthGrid();
        } else {
          if (imaginarySouth > 0) {
            removeImaginarySouthGrid();
          }
          robotIndex = robotIndex - _columns;
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "E") {
        if (robotIndex % _columns != _columns - 1) {
          if (imaginaryWest > 0) {
            removeImaginaryWestGrid();
          } else {
            robotIndex = robotIndex + 1;
          }
        } else {
          createImaginaryEastGrid();
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "S") {
        if (robotIndex >= (_columns * (_rows - 1))) {
          createImaginarySouthGrid();
        } else {
          if (imaginaryNorth > 0) {
            removeImaginaryNorthGrid();
          } else {
            robotIndex = (robotIndex + _columns);
          }
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "W") {
        if (robotIndex % _columns != 0) {
          if (imaginaryEast > 0) {
            removeImaginaryEastGrid();
          } else {
            robotIndex = robotIndex - 1;
          }
        } else {
          createImaginaryWestGrid();
        }
      }
    });
  }

  moveReverse() {
    statusMessage = "Reversing...";

    setState(() {
      if (robotCurrentDirection == "N") {
        if (robotIndex >= _columns * (_rows - 1)) {
          createImaginarySouthGrid();
        } else {
          if (imaginaryNorth > 0) {
            /*imaginaryNorth -=1;
            _rows -= 1;
            _columns -= 1;*/
            removeImaginaryNorthGrid();
          } else {
            robotIndex = robotIndex + _columns;
          }
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "E") {
        if (robotIndex % _columns < 1) {
          createImaginaryWestGrid();
        } else {
          if (imaginaryEast > 0) {
            removeImaginaryEastGrid();
          } else {
            robotIndex = robotIndex - 1;
          }
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "S") {
        if (robotIndex < _columns) {
          createImaginaryNorthGrid();
        } else {
          if (imaginarySouth > 0) {
            removeImaginarySouthGrid();
          }
          robotIndex = (robotIndex - _columns);
        }
        print(robotIndex);
      } else if (robotCurrentDirection == "W") {
        if (robotIndex % _columns == _columns - 1) {
          createImaginaryEastGrid();
        } else {
          if (imaginaryWest > 0) {
            removeImaginaryWestGrid();
          } else {
            robotIndex = robotIndex + 1;
          }
        }
      }
    });
  }

  /* moveForward() {
    setState(() {
      if(robotCurrentDirection == "N"){
        robotIndex = robotIndex - _columns;
      }

      else if(robotCurrentDirection == "E"){
        robotIndex = robotIndex+1;
      }

      else if(robotCurrentDirection == "S"){
        robotIndex = (robotIndex+_columns);
      }

      else if(robotCurrentDirection == "W"){
        robotIndex = robotIndex-1;
      }
    });
  }

  moveReverse() {
    setState(() {
      if(robotCurrentDirection == "N"){
        robotIndex = robotIndex + _columns;
      }

      else if(robotCurrentDirection == "E"){
        robotIndex = robotIndex-1;
        }

      else if(robotCurrentDirection == "S"){
        robotIndex = (robotIndex-_columns);
      }

      else if(robotCurrentDirection == "W"){
        robotIndex = robotIndex+1;
      }
    });
  }*/

  rotateLeft() {
    statusMessage = "Turning Left...";

    setState(() {
      if (robotAngle < -6) {
        robotAngle = 0;
      }
      robotAngle -= pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    return robotAngle;
  }

  forwardLeft() {
    setState(() {
      moveForward();
      if (robotAngle < -6) {
        robotAngle = 0;
      }
      robotAngle -= pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    moveForward();
    return robotAngle;
  }

  reverseLeft() {
    setState(() {
      moveReverse();
      if (robotAngle < -6) {
        robotAngle = 0;
      }
      robotAngle += pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    moveReverse();
    return robotAngle;
  }

  rotateRight() {
    statusMessage = "Turning Right...";

    setState(() {
      if (robotAngle > 6) {
        robotAngle = 0;
      }
      robotAngle += pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    return robotAngle;
  }

  forwardRight() {
    setState(() {
      moveForward();
      if (robotAngle > 6) {
        robotAngle = 0;
      }
      robotAngle += pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    moveForward();
    return robotAngle;
  }

  reverseRight() {
    setState(() {
      moveReverse();
      if (robotAngle > 6) {
        robotAngle = 0;
      }
      robotAngle -= pi / 2;
      checkRobotDirection();
    });
    print("Angle is: $robotAngle");
    moveReverse();
    return robotAngle;
  }

  checkRobotDirection() {
    if (robotAngle % (pi * 2) == pi * 0.5) {
      robotCurrentDirection = "E";
    } else if (robotAngle % (pi * 2) == pi) {
      robotCurrentDirection = "S";
    } else if (robotAngle % (pi * 2) == pi * 1.5) {
      robotCurrentDirection = "W";
    } else if (robotAngle % (pi * 2) == 0) {
      robotCurrentDirection = "N";
    }
  }

  setRobotDirection(direction) {
    setState(() {
      if (direction == "E") {
        robotAngle = pi * 0.5;
      } else if (direction == "S") {
        robotAngle = pi;
      } else if (direction == "W") {
        robotAngle = pi * 1.5;
      } else if (direction == "N") {
        robotAngle = 0;
      }
    });
  }

  setRobotLocation(x, y, direction) {
    print("Received message to update robot location");
    print("$x, $y, $direction");

    if (x < _columns && y < _rows) {
      setState(() {
        robotIndex = x + _columns * (y);
        robotCurrentDirection = direction;
        setRobotDirection(direction);
      });
    } else {
      setState(() {
        robotIndex = -1;
      });
    }
  }

  void confirmStopDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        // disables popup to close if tapped outside popup (need a button to close)
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning),
                Text("Are you sure?"),
              ],
            ),
            content: Text(
                "By pressing confirm, you are stopping the robot operations. Continue?"),
            //buttons?
            actions: <Widget>[
              TextButton(
                child: Text("Confirm"),
                onPressed: () {
                  if (isStarted == true) {
                    _sendMessage("PC:STOP");
                    isStarted = false;
                  }
                  Navigator.of(context).pop();
                }, //closes popup
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                }, //closes popup
              ),
            ],
          );
        });
  }

  void changeGridDialog(BuildContext context) {
    showGeneralDialog(
        barrierLabel: "Barrier",
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: Duration(milliseconds: 700),
        context: context,
        pageBuilder: (_, __, ___) {
          return StatefulBuilder(
            builder: (context, setState) {
             return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 300,
                  child: SizedBox.expand(
                      child: Card(
                       child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                        children: <Widget>[
                          InputField(
                              labelText: "Row",
                              hintText: "20",
                              onChanged: (row) {
                                setState(() {
                                  _updatedRow = int.parse(row);
                                });
                              }
                          ),
                          InputField(
                              labelText: "Column",
                              hintText: "20",
                              onChanged: (column) {
                                setState(() {
                                  _updatedColumn = int.parse(column);
                                });
                              }
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                error,
                                style:
                                TextStyle(color: Colors.red,
                                  fontSize: 14,
                                )
                            ),
                          ),

                          RoundedButton(
                            text: "OK",
                            onSubmit: () async {
                              // if (_formKey.currentState!.validate()){

                                try {
                                  if(_updatedRow==-1 || _updatedColumn==-1)
                                    throw Exception("Row and column cannot be empty");

                                  else if(_updatedRow==0 || _updatedColumn==0)
                                    throw Exception("Row and column cannot be 0");

                                  else if(_updatedRow>20 || _updatedColumn>20)
                                    throw Exception("Row and column cannot be more than 20");

                                  else if(_updatedRow==1 || _updatedColumn==1)
                                    throw Exception("Row and column must be more than 1");


                                  else {
                                    setState(() {
                                    _rows = _updatedRow;
                                    _columns = _updatedColumn;
                                    error = 'Updated. Please close dialog box to see the changes.';

                                    });
                                  }

                                } catch (e) {
                                  setState(() {
                                    error = e.toString();
                                  });
                                }
                              // }
                            },

                          ),


                        ]),
                      ),

                  ),
                ),
              ),
            );
          });
        },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim),
          child: child,
        );
      },
    ).then((val) {
      setState(() {
        error = '';
      });
    });
    }

  void changeGridHeight(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 700),
      context: context,
      pageBuilder: (_, __, ___) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 300,
                  child: SizedBox.expand(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                            children: <Widget>[

                              InputField(
                                  labelText: "Height of Grid",
                                  hintText: ".5",
                                  onChanged: (height) {
                                    setState(() {
                                      _updatedHeight = double.parse(height);
                                    });
                                  }
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                    error,
                                    style:
                                    TextStyle(color: Colors.red,
                                      fontSize: 14,
                                    )
                                ),
                              ),

                              RoundedButton(
                                text: "OK",
                                onSubmit: () async {
                                  // if (_formKey.currentState!.validate()){

                                  try {
                                    if(_updatedHeight > 1 || _updatedHeight <= 0)
                                      throw Exception("Height must be between 0 - 1");

                                    else if(_updatedHeight==-1)
                                      throw Exception("Height cannot be empty");


                                    else {
                                      setState(() {
                                        _height = _updatedHeight;
                                        error = 'Updated. Please close dialog box to see the changes.';

                                      });
                                    }

                                  } catch (e) {
                                    setState(() {
                                      error = e.toString();
                                    });
                                  }
                                  // }
                                },

                              ),


                            ]),
                      ),

                    ),
                  ),
                ),
              );
            });
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim),
          child: child,
        );
      },
    ).then((val) {
      setState(() {
        error = '';
      });
    });
  }

  void onSelected(BuildContext context, int item) {
    switch(item) {
      case 0:
        changeGridDialog(context);
            break;
      case 1:
        changeGridHeight(context);
            break;

    }
  }
}

class Obstacle {
  var index;
  var id;
  var direction;
  var action;
  bool discovered = false;

  // get oid => this.id;
  get isDiscovered => this.discovered;

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

  static Obstacle updateDiscovery(Obstacle obstacle, bool discovered) {
    obstacle.discovered = discovered;
    return obstacle;
  }

  Obstacle(
      {required this.id, this.index, this.direction});
}
