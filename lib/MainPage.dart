import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mdp3004/GridArena.dart';
// import 'package:mdp3004/BluetoothBroadcastState.dart';
import 'package:scoped_model/scoped_model.dart';

import './BackgroundCollectedPage.dart';
import './BackgroundCollectingTask.dart';
import './ChatPage.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import 'BluetoothConnection.dart';
import 'Controls.dart';


// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  static late BluetoothDevice server;
  static var serverAddress;
  static BluetoothConnection? connection;
  static bool isConnecting = false;
  static bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

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
            ListTile(title: const Text('General')),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Broadcast.instance!=null? Text('Live chat with ' + serverAddress.toString())
                  : Text('Disconnected'),
              trailing: ElevatedButton(
                child: const Text('Settings'),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
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

            /*Divider(),
            ListTile(title: const Text('Devices discovery and connection')),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 1234'),
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler(
                          (BluetoothPairingRequest request) {
                        print("Trying to auto-pair with Pin 1234");
                        if (request.pairingVariant == PairingVariant.Pin) {
                          return Future.value("1234");
                        }
                        return Future.value(null);
                      });
                } else {
                  FlutterBluetoothSerial.instance
                      .setPairingRequestHandler(null);
                }
              },
            ),*/


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
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Connect to paired device to chat'),
                onPressed: () async {
                  final BluetoothDevice? selectedDevice =
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);

                    print(isConnected);
                    server = selectedDevice;
                    serverAddress = selectedDevice.address;
                    _establishConnection(context, server!);
                    print("Establishing connection...");
                    print(isConnected);

                    //_startChat(context, selectedDevice);
                  } else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Chat Page'),
                onPressed: ()  {
                  _startChat(context, server!);
                },
              ),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Controls'),
                onPressed: ()  {
                  _startControl(context, server!);
                },
              ),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Connection status'),
                onPressed: ()  {
                  print("Print Server: $server");
                  print("Is connected?: " + isConnected.toString());
                  print("Connection Status: " + connection.toString());
                  print("Broadcast instance is bonded?:");
                  //print(Broadcast.instance);
                  print(Broadcast.instance!=null?.toString());
                  //(BluetoothStateBroadcastWrapper.connection);
                  print("Server address: $serverAddress");

                },
              ),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Reconnect'),
                onPressed: ()  {
                  if(!isConnected) {
                    getConnection();

                  }

                  else
                    {print("Already connected!");}
                  setState(() {

                  });
                },
              ),
            ),
            ListTile(
              title: ElevatedButton(
                child: const Text('Disconnect'),
                onPressed: ()  {
                  print("Before" + isConnected.toString());
                  _disconnect(context, server!);
                  print("After" + isConnected.toString());
                },
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }

  void _establishConnection(BuildContext context, BluetoothDevice server) {
    isConnecting = true;

    try{
      if (connection == null){
        getConnection();
      } else {
        listenToStream();
      }

    } catch (e) {
      print(e);
    }

  }

  //   BluetoothConnection.toAddress(server.address).then((_connection) {
  //
  //     connection = _connection;
  //     print('Connected to the device');
  //     print('Connection is: $connection');
  //     print('Connection address: ' + server.address);
  //
  //     setState(() {
  //       isConnecting = false;
  //       isDisconnecting = false;
  //       print("Connection is: " + connection.toString());
  //       getConnection(server.address);
  //     });
  //   }).catchError((error) {
  //     print('Cannot connect, exception occured');
  //     print(error);
  //   });
  // }

  /*void listenToStream() {

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

    });*/


  void getConnection() async {
    await Broadcast.setInstance(await BluetoothStateBroadcastWrapper.create(server.address));
    connection = BluetoothStateBroadcastWrapper.connection;
    setState(() {

    });

    //listenToStream();

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

  void _disconnect(BuildContext context, BluetoothDevice server) {
    // Avoid memory leak (`setState` after dispose) and disconnect
    print("Disconnect button is pressed, isConnected status:");
    print(isConnected);
    print("Connection is: " + connection.toString());
    print("Server is: " + server.toString());

    //Broadcast.instance.dispose();
    //BluetoothStateBroadcastWrapper.connection.dispose();
    Broadcast.setInstance(null);
    print("Broadcast instance is:");
    print(Broadcast.instance);

    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    setState(() {

    });

    print("After disconnecting:");

    print(server.bondState);
    print("Connection is $connection");
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

  void _startControl(BuildContext context, BluetoothDevice server) {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ControlsPage(server: server);
        },
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
