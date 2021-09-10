import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rxdart/rxdart.dart';

class BluetoothStateBroadcastWrapper {

  static var connection;
  // get btCon => connection;

  BehaviorSubject<Uint8List> _stateStreamController = BehaviorSubject();
  Stream<Uint8List> get btStateStream => _stateStreamController.stream;

  late StreamSubscription<Uint8List> _sub;

  // static BluetoothStateBroadcastWrapper instance =
  // BluetoothStateBroadcastWrapper._initState();

  static Future<BluetoothStateBroadcastWrapper> create(server) async {

    try {
      print("setconnection");
      await setConnection(server).then((con) =>
        print("done")
      );
      print(connection);

    } catch (e){
      print(e);
    }

    print("return");
    var instance = BluetoothStateBroadcastWrapper._initState();
    return instance;
  }


  BluetoothStateBroadcastWrapper._initState() {

    print(connection);
    print("private");
    if (connection != null) {
      print("btcon");
      _sub = connection.input.listen((obj) => _stateStreamController.sink.add(obj));

    }
  }

  static Future<BluetoothConnection> setConnection (server) async {
    connection = await BluetoothConnection.toAddress(server);
    return connection;
  }

  void dispose() {

    _stateStreamController?.close();
    _sub?.cancel();
    connection = null;
    //TODO: Close connection

  }


}

class Broadcast extends ChangeNotifier {

  static var instance;

  static Future<BluetoothStateBroadcastWrapper> setInstance(broadcast) async {
    instance = await broadcast;
    return instance;
  }

}



