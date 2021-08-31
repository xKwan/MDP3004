
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/ChatPage.dart';

import './BluetoothDeviceListEntry.dart';
import './MainPage.dart';

class SelectBondedDevicePage extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not avaliable, they would be disabled from the selection.
  final bool checkAvailability;
  var connection;
  var broadcast;

  // const SelectBondedDevicePage({this.checkAvailability = true, this.connection});
  SelectBondedDevicePage({ this.checkAvailability = true, this.connection, this.broadcast });

  @override
  _SelectBondedDevicePage createState() => new _SelectBondedDevicePage(connection, broadcast);
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int? rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectBondedDevicePage extends State<SelectBondedDevicePage> {
  List<_DeviceWithAvailability> devices =
  List<_DeviceWithAvailability>.empty(growable: true);
  bool reload = false;

  // Availability
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  bool _isDiscovering = false;

  _SelectBondedDevicePage(this.connection, this.broadcast);

  var connection;
  var broadcast;

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    // Setup a list of the bonded devices
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map(
              (device) => _DeviceWithAvailability(
                device,
                widget.checkAvailability
                    ? _DeviceAvailability.maybe
                    : _DeviceAvailability.yes,
              ),
            )
            .toList();
      });
    });
  }

  void _restartDiscovery() {
    setState(() {});
    reload = true;

  }

  void _startDiscovery() {
    _discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        Iterator i = devices.iterator;
        while (i.moveNext()) {
          var _device = i.current;
          if (_device.device == r.device) {
            _device.availability = _DeviceAvailability.yes;
            _device.rssi = r.rssi;
          }
        }
      });
    });

    _discoveryStreamSubscription?.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDeviceListEntry> list = devices
        .map((_device) => BluetoothDeviceListEntry(
              device: _device.device,
              rssi: _device.rssi,
              enabled: _device.availability == _DeviceAvailability.yes,
              onTap: () {
                print("bond");
                print(connection);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return ChatPage(server:_device.device, broadcast: broadcast,);
                    },
                  ),
                );
              },
            ))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Select device'),
        actions: <Widget>[
          reload
              ? FittedBox(
                  child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: _restartDiscovery, //Reload page
                )
        ],
      ),
      body: ListView(children: list),
    );
  }
}
