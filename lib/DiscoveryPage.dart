import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/ChatPage.dart';

import './BluetoothDeviceListEntry.dart';

class DiscoveryPage extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryPage({this.start = true});

  @override
  _DiscoveryPage createState() => new _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
  List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;
  bool failure = true;

  _DiscoveryPage();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }


  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (r.device.name != null)
        {
          if (existingIndex >= 0)
            results[existingIndex] = r;
          else
            results.add(r);
        }
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  Future<bool> failureDialog() async {
    return failure ? await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("Failed to connect to device"),
        actions: [
          TextButton(
              child: Text("Ok", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.pop(context, false);
              }),

        ],
      ),
    ): "";
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isDiscovering
            ? Text('Discovering devices')
            : Text('Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: _restartDiscovery,
                )
        ],
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext context, index) {
          BluetoothDiscoveryResult result = results[index];
          final device = result.device;
          final address = device.address;
          return BluetoothDeviceListEntry(
            device: device,
            rssi: result.rssi,
            // onTap: () {
            //   Navigator.of(context).pop(result.device);
            // },
            onTap: () async {

              // FlutterBluetoothSerial.instance.onStateChanged().listen((state) async {

                try {
                  bool bonded = false;
                  var bond;
                  int tries = 0;

                  if (device.isBonded) {
                    print('Unbonding from ${device.address}...');
                    await FlutterBluetoothSerial.instance
                        .removeDeviceBondWithAddress(address);
                    print('Unbonding from ${device.address} has succeed');

                  } else {

                    // do{
                      print('Bonding with ${device.address}...');
                      bonded = (await FlutterBluetoothSerial.instance
                          .bondDeviceAtAddress(address))!!;

                      print(bonded);

                    //   tries++;
                    //
                    // } while(!bonded && tries < 11);

                    print('Bonding with ${device.address} has ${bonded ? 'succeeded' : 'failed'}.');

                    bonded ?
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ChatPage(server: device);
                        },
                      ),
                    ) :
                    setState(() {
                      failure = true;
                      failureDialog();
                    });

                  }

                  setState(() {
                  print("setstate");
                  results[results.indexOf(result)] = BluetoothDiscoveryResult(
                      device: BluetoothDevice(
                      name: device.name ?? '',
                      address: address,
                      type: device.type,
                      bondState: bonded
                      ? BluetoothBondState.bonded
                      : BluetoothBondState.none,
                  ),
                  rssi: result.rssi);
                  });

              } catch (ex) {
                  showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                       title: const Text('Error occurred while bonding'),
                      content: Text("${ex.toString()}"),
                      actions: <Widget>[
                      new TextButton(
                        child: new Text("Close"),
                        onPressed: () {
                        Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }


          // });


            },
          );
        },
      ),
    );
  }
}
