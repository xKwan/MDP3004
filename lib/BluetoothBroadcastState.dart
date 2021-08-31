import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import'BluetoothConnection.dart';

class Broadcast {

  static var instance;

  static Future<BluetoothStateBroadcastWrapper> setInstance(broadcast) async {
    instance = await broadcast;
    return instance;
  }

}