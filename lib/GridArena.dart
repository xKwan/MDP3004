import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mdp3004/helpers/CustomDialog.dart';
import 'BluetoothConnection.dart';

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
  int _columns = 16;
  int _rows = 16;

  List<int> _index = [];
  int robotIndex = -1;
  var _action = action.UNKNOWN;
  double robotAngle = 0;
  var robotCurrentDirection = "0";
  bool isStarted = false;

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

  Widget dragTarget(context, index) => DragTarget<Obstacle>(
      builder: (context, candidateData, rejectedData) => Container(
            child:
                //Check if robot has been placed
                robotIndex == index
                    ? buildRotateRobot()
                    :
                    //Else check if obstacle has been placed
                    _index.contains(index)
                        ? Text(obstacles[index]!.id.toString(),
                            style: TextStyle(color: Colors.white))
                        : null,
          ),
      onWillAccept: (data) => true,
      onAccept: (data) {
        setState(() {
          if (data.action == action.ADD) {
            if (!_index.contains(index)) {
              _index.add(index);
              data = Obstacle.updateId(data, obstacles.entries.length + 1);
              data = Obstacle.updateIndex(data, index);
              obstacles.addAll({index: data});
              print(obstacles);

              _sendMessage("ADD, $index, (" +
                  getObstacleCoordinates(obstacles[index]!)["x"].toString() +
                  ", " +
                  getObstacleCoordinates(obstacles[index]!)["y"].toString() +
                  ")");
            }
          }
        });
      });

  Widget buildRotateRobot() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //Text(robotCurrentDirection),
        //Text(robotIndex.toString()),
        Transform.rotate(
          angle: robotAngle,
          child: Expanded(
            child: FittedBox(
              child: Icon(
                Icons.arrow_upward_sharp,
                color: Colors.red,
                //size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget rebuildCard(BuildContext context, index) => Card(
        color: (_index.contains(index)) ? Colors.blueGrey : Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
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
            child: _index.contains(index)
                ? Draggable<Obstacle>(
                    data:
                        Obstacle.updateAction(obstacles[index]!, action.REMOVE),
                    child: dragTarget(context, index),
                    feedback: Material(
                        child: Icon(Icons.view_in_ar, color: Colors.black)),
                  )
                : dragTarget(context, index),
          ),
        ),
      );

  Map<String, int> getRobotCoordinates() {
    Map<String, int> cord = {"x": -1, "y": -1};
    if (robotIndex != -1) {
      cord["x"] = robotIndex % _columns;
      cord["y"] = (robotIndex / _columns).floor();
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

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.cyan,
          title: DragTarget<Obstacle>(
              builder: (context, candidateData, rejectedData) => Container(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: <Widget>[
                        //Change dimension of grid
                        IconButton(
                            onPressed: () async => {
                                  await CustomDialog.showDialog(context)
                                      .then((gridVal) => setState(() {
                                            print("Set");
                                            _columns = gridVal["column"]!;
                                            _rows = gridVal["row"]!;
                                          })),
                                },
                            icon: Icon(Icons.apps)),

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
                        Draggable<Obstacle>(
                          data: new Obstacle(action: action.ADD),
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.view_in_ar)),
                          feedback: Material(
                              child:
                                  Icon(Icons.view_in_ar, color: Colors.black)),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(10.0, 8.0, 0.0, 8.0),
                          child: Container(
                            child: Text(
                              "(" +
                                  getRobotCoordinates()["x"].toString() +
                                  " , " +
                                  getRobotCoordinates()["y"].toString() +
                                  ")",
                              style: TextStyle(
                                fontSize: 25.0,
                              ),
                              // maxLines: 2,   // TRY THIS
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(robotCurrentDirection),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text("(" + robotIndex.toString() + ")"),
                        ),
                      ],
                    ),
                  ),
              onWillAccept: (data) => true,
              onAccept: (data) {
                setState(() {
                  if (data.action == action.REMOVE) {
                    _index.remove(data.index);
                    obstacles.remove(data.index);
                    print(obstacles);

                    _sendMessage("SUB, " + data.index.toString());
                  }
                });
              }),
        ),
        resizeToAvoidBottomInset: false,
        body: Container(
          child: Column(
            children: [
              Container(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 0.0),
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                        "   0      1      2      3      4      5      6      7      8      9      10      11      12      13      14      15      16      17      18      19  "),
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    //width: MediaQuery.of(context).size.width*.7,
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
                              if (_action == action.PLACE) {
                                robotIndex = index;
                                if(robotCurrentDirection == '0'){
                                  robotCurrentDirection = "N";
                                }
                                var text = ("ROBOT," + getRobotCoordinates()["x"].toString() + ","
                                    + getRobotCoordinates()["y"].toString() + "," + robotCurrentDirection);
                                _sendMessage(text);
                              }
                            })
                          },
                          child: GestureDetector(
                              onLongPressMoveUpdate: (updates) => {
                                    setState(() {
                                      if (updates.localOffsetFromOrigin.dx >
                                              0 &&
                                          updates.localOffsetFromOrigin.dy! >
                                              updates
                                                  .localOffsetFromOrigin.dx) {
                                        Obstacle.updateDirection(
                                            obstacles[index]!, "S");

                                        _sendMessage("FACE, $index, S");
                                      } else if (updates
                                                  .localOffsetFromOrigin.dx <
                                              0 &&
                                          updates.localOffsetFromOrigin.dy! >
                                              updates
                                                  .localOffsetFromOrigin.dx) {
                                        Obstacle.updateDirection(
                                            obstacles[index]!, "W");

                                        _sendMessage("FACE, $index, W");
                                      } else if (updates
                                              .localOffsetFromOrigin.dy >
                                          0) {
                                        Obstacle.updateDirection(
                                            obstacles[index]!, "E");

                                        _sendMessage("FACE, $index, E");
                                      } else if (updates
                                              .localOffsetFromOrigin.dy <
                                          0) {
                                        Obstacle.updateDirection(
                                            obstacles[index]!, "N");

                                        _sendMessage("FACE, $index, N");
                                      }
                                    })
                                  },
                              child: rebuildCard(context, index)),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              Divider(thickness: 2),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    child: Column(
                      children: [
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
                        Text("Robot moving?: " + isStarted.toString()),
                        Divider(thickness: 2),

                        IntrinsicHeight(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _sendMessage('STM: start');
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
                                    //_sendMessage('STM: stop');
                                    if(isStarted == true)
                                      {
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
                                    _sendMessage('STM: tl');
                                    getSentText('Turn Left');
                                     /*var text = _encodeString('f');
                                     _onDataReceived(text);*/
                                  },
                                  style: ElevatedButton.styleFrom(
                                      //fixedSize: Size(240, 80),
                                      primary: Colors.lightBlueAccent),
                                  icon: Icon(Icons.keyboard_arrow_left_outlined),
                                  label: Text('Fwd Left'),
                                ),
                              ),
                              VerticalDivider(width: 10.0, thickness: 2),
                              SizedBox(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    print('Forward');
                                    moveForward();
                                    _sendMessage('STM: f');
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
                                    _sendMessage('STM: tr');
                                    getSentText('Turn Right');
                                     /*var text = _encodeString('f');
                                     _onDataReceived(text);*/
                                  },
                                  style: ElevatedButton.styleFrom(
                                      //fixedSize: Size(240, 80),
                                      primary: Colors.lightBlueAccent),
                                  icon: Icon(Icons.keyboard_arrow_right_outlined),
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
                                  _sendMessage('tl');
                                  var text = _encodeString('l');
                                  _onDataReceived(text);
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
                                  _sendMessage('tr');
                                  var text = _encodeString('r');
                                  _onDataReceived(text);
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
                                    *//*_sendMessage('f');
                                     var text = _encodeString('f');
                                     _onDataReceived(text);*//*
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
                                    *//*_sendMessage('f');
                                     var text = _encodeString('f');
                                     _onDataReceived(text);*//*
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
        ));
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

      print(dataString.split(',')[0]);
      if (dataString.split(',')[0] == "ROBOT") {
        dataString = dataString.toUpperCase();
        print("Received ROBOT Command");
        setRobotLocation(int.parse(dataString.split(',')[1]),
            int.parse(dataString.split(',')[2]), dataString.split(',')[3]);
      } else if (dataString.split(',')[0] == "TARGET") {
        if (obstacles[dataString.split(',')[1]] != null) {
          Obstacle data = Obstacle.updateId(
              obstacles[dataString.split(',')[1]]!,
              obstacles[dataString.split(',')[2]]);
          obstacles.update(
              int.parse(dataString.split(',')[1]), (value) => data);
        } else {
          Obstacle data = new Obstacle(
              id: int.parse(dataString.split(',')[2]),
              index: int.parse(dataString.split(',')[1]),
              action: action.UNKNOWN);
          _index.add(int.parse(dataString.split(',')[1]));
          obstacles.addAll({int.parse(dataString.split(',')[1]): data});
        }

        try {
          print("Try");
          Obstacle updatedObstacle = Obstacle.updateDirection(
              obstacles[int.parse(dataString.split(',')[1])]!,
              dataString.split(',')[3].toString());
          obstacles.update(
              int.parse(dataString.split(',')[1]), (value) => updatedObstacle);
        } catch (e) {
          print(e);
        }
      }
    });
    print("RECEIVED: $dataString");
    return dataString;
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

        if(mounted){
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

  moveForward() {
    setState(() {
      if(robotCurrentDirection == "N"){
        if(robotIndex < _columns);
        else {
          robotIndex = robotIndex - _columns;
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "E"){
        if (robotIndex%_columns != _columns-1) {
          robotIndex = robotIndex+1;
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "S"){
        if (robotIndex >= (_columns*(_rows-1)));
        else {
          robotIndex = (robotIndex+_columns);
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "W"){
        if (robotIndex%_columns != 0) {
          robotIndex = robotIndex-1;
        }

      }
    });
  }

  moveReverse() {
    setState(() {
      if(robotCurrentDirection == "N"){
        if(robotIndex >= _columns*(_rows-1));
        else {
          robotIndex = robotIndex + _columns;
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "E"){
        if (robotIndex%_columns < 1);
        else {
          robotIndex = robotIndex-1;
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "S"){
        if (robotIndex < _columns);
        else {
          robotIndex = (robotIndex-_columns);
        }
        print(robotIndex);
      }

      else if(robotCurrentDirection == "W"){
        if (robotIndex%_columns == _columns-1);
        else {
          robotIndex = robotIndex+1;
        }
      }
    });
  }

  rotateLeft() {
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

    setState(() {
      robotIndex = x + (_columns * (y));
      robotCurrentDirection = direction;
      setRobotDirection(direction);
    });
  }

  void confirmStopDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false, // disables popup to close if tapped outside popup (need a button to close)
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning),
                Text("Are you sure?"),
              ],
            ),
            content: Text("By pressing confirm, you are stopping the robot operations. Continue?"),
            //buttons?
            actions: <Widget>[
              TextButton(
                child: Text("Confirm"),
                onPressed: () {
                  if(isStarted == true){
                    _sendMessage("STM: stop");
                    isStarted = false;
                  }
                  Navigator.of(context).pop();
                }, //closes popup
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () { Navigator.of(context).pop(); }, //closes popup
              ),
            ],
          );
        }
    );
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

  Obstacle({this.id, this.index, this.direction, required this.action});
}
