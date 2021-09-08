import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/GridArena.dart';
import 'bin/testpage.dart';
// import 'package:mdp3004/BluetoothBroadcastState.dart';
import 'package:scoped_model/scoped_model.dart';

import './BackgroundCollectedPage.dart';
import './BackgroundCollectingTask.dart';
import './ChatPage.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import 'BluetoothConnection.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  // var connection;
  // var broadcast;
  BluetoothDevice? selectedDevice;

  // const MainPage({ this.connection, this.selectedDevice });

  MainPage({ this.selectedDevice });

  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // var connection  = BluetoothStateBroadcastWrapper.connection;

  String _address = "...";
  String _name = "...";

  BluetoothDevice _connectedDevice = BluetoothDevice(address: '');

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;
  bool get isConnected => (Broadcast.instance!=null ? true : false);


  // _MainPage(this.connection, this.selectedDevice, this.broadcast);

  // get selectedDevice => this.selectedDevice ;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;


        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });


  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Bluetooth Serial'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            // ListTile(title: const Text('General')),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                // if(!_bluetoothState.isEnabled){
                //   // print(Broadcast.instance);
                //   print("DISPOSE");
                //   Broadcast.instance.dispose();
                //   Broadcast.setInstance(null);
                // }

                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                  {
                    await FlutterBluetoothSerial.instance.requestDisable();
                    Broadcast.instance.dispose();
                    Broadcast.setInstance(null);
                  }
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Text(isConnected ? "Connected: "+_connectedDevice.address : "Disconnected"),
              trailing: ElevatedButton(
                child: const Text('Disconnect'),
                onPressed: () {
                  // FlutterBluetoothSerial.instance.openSettings();
                  if(Broadcast.instance != null) {
                    Broadcast.instance.dispose();
                    Broadcast.setInstance(null);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Local adapter address'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: const Text('Local adapter name'),
              subtitle: Text(_name),
              onLongPress: null,
            ),
            // ListTile(
            //   title: _discoverableTimeoutSecondsLeft == 0
            //       ? const Text("Discoverable")
            //       : Text(
            //           "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
            //   subtitle: const Text("PsychoX-Luna"),
            //   trailing: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Checkbox(
            //         value: _discoverableTimeoutSecondsLeft != 0,
            //         onChanged: null,
            //       ),
            //       IconButton(
            //         icon: const Icon(Icons.edit),
            //         onPressed: null,
            //       ),
            //       // IconButton(
            //       //   icon: const Icon(Icons.refresh),
            //       //   onPressed: () async {
            //       //     print('Discoverable requested');
            //       //     final int timeout = (await FlutterBluetoothSerial.instance
            //       //         .requestDiscoverable(60))!;
            //       //     if (timeout < 0) {
            //       //       print('Discoverable mode denied');
            //       //     } else {
            //       //       print(
            //       //           'Discoverable mode acquired for $timeout seconds');
            //       //     }
            //       //     setState(() {
            //       //       _discoverableTimeoutTimer?.cancel();
            //       //       _discoverableTimeoutSecondsLeft = timeout;
            //       //       _discoverableTimeoutTimer =
            //       //           Timer.periodic(Duration(seconds: 1), (Timer timer) {
            //       //         setState(() {
            //       //           if (_discoverableTimeoutSecondsLeft < 0) {
            //       //             FlutterBluetoothSerial.instance.isDiscoverable
            //       //                 .then((isDiscoverable) {
            //       //               if (isDiscoverable ?? false) {
            //       //                 print(
            //       //                     "Discoverable after timeout... might be infinity timeout :F");
            //       //                 _discoverableTimeoutSecondsLeft += 1;
            //       //               }
            //       //             });
            //       //             timer.cancel();
            //       //             _discoverableTimeoutSecondsLeft = 0;
            //       //           } else {
            //       //             _discoverableTimeoutSecondsLeft -= 1;
            //       //           }
            //       //         });
            //       //       });
            //       //     });
            //       //   },
            //       // )
            //     ],
            //   ),
            // ),
            Divider(),
            ListTile(
              title: ElevatedButton(
                child: const Text('Grid Arena'),
                onPressed: () async {
                  Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return GridArena();
                        },
                    )
                  );
                }

            )),
            // SwitchListTile(
            //   title: const Text('Auto-try specific pin when pairing'),
            //   subtitle: const Text('Pin 1234'),
            //   value: _autoAcceptPairingRequests,
            //   onChanged: (bool value) {
            //     setState(() {
            //       _autoAcceptPairingRequests = value;
            //     });
            //     if (value) {
            //       FlutterBluetoothSerial.instance.setPairingRequestHandler(
            //           (BluetoothPairingRequest request) {
            //         print("Trying to auto-pair with Pin 1234");
            //         if (request.pairingVariant == PairingVariant.Pin) {
            //           return Future.value("1234");
            //         }
            //         return Future.value(null);
            //       });
            //     } else {
            //       FlutterBluetoothSerial.instance
            //           .setPairingRequestHandler(null);
            //     }
            //   },
            // ),
            ListTile(
              title: ElevatedButton(
                  child: const Text('Explore discovered devices'),
                  onPressed: () async {
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoveryPage();
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                      _connectedDevice = selectedDevice;

                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Connect to paired device to chat'),
                onPressed: () async {

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: true);
                      },
                    ),
                  );

                  // if (selectedDevice != null) {
                  //   print('Connect -> selected ' + selectedDevice.address);
                  //   _startChat(context, selectedDevice);
                  // } else {
                  //   print('Connect -> no device selected');
                  // }
                },
              ),
            ),
            // Divider(),
            // ListTile(title: const Text('Multiple connections example')),
            // ListTile(
            //   title: ElevatedButton(
            //     child: ((_collectingTask?.inProgress ?? false)
            //         ? const Text('Disconnect and stop background collecting')
            //         : const Text('Connect to start background collecting')),
            //     onPressed: () async {
            //       if (_collectingTask?.inProgress ?? false) {
            //         await _collectingTask!.cancel();
            //         setState(() {
            //           /* Update for `_collectingTask.inProgress` */
            //         });
            //       } else {
            //         final BluetoothDevice? selectedDevice =
            //             await Navigator.of(context).push(
            //           MaterialPageRoute(
            //             builder: (context) {
            //               return SelectBondedDevicePage(
            //                   checkAvailability: false);
            //             },
            //           ),
            //         );
            //
            //         if (selectedDevice != null) {
            //           await _startBackgroundTask(context, selectedDevice);
            //           setState(() {
            //             /* Update for `_collectingTask.inProgress` */
            //           });
            //         }
            //       }
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: ElevatedButton(
            //     child: const Text('View background collected data'),
            //     onPressed: (_collectingTask != null)
            //         ? () {
            //             Navigator.of(context).push(
            //               MaterialPageRoute(
            //                 builder: (context) {
            //                   return ScopedModel<BackgroundCollectingTask>(
            //                     model: _collectingTask!,
            //                     child: BackgroundCollectedPage(),
            //                   );
            //                 },
            //               ),
            //             );
            //           }
            //         : null,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
    BuildContext context,
    BluetoothDevice server,
  ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask!.start();
    } catch (ex) {
      _collectingTask?.cancel();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
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
  }
}
