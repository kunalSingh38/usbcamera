import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usb_camera/camerPreview.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

class ConnectTODevice extends StatefulWidget {
  @override
  _ConnectTODeviceState createState() => _ConnectTODeviceState();
}

class _ConnectTODeviceState extends State<ConnectTODevice> {
  late List<CameraDescription> _cameras;

  UsbPort? _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];
  String dataFromPort = "";

  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  UsbDevice? _device;

  TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port!.close();
      _port = null;
    }

    if (device == null) {
      _device = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (await (_port!.open()) != true) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }
    _device = device;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>, Uint8List.fromList([13, 10]));

    _subscription = _transaction!.stream.listen((String line) {
      setState(() {
        _serialData.add(Text(line));
        dataFromPort = line.toString();
        print(line);
        if (_serialData.length > 20) {
          _serialData.removeAt(0);
        }
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  bool showButton = false;
  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (!devices.contains(_device)) {
      _connectTo(null);
    }

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text("Test"),
          // subtitle: Text(device.manufacturerName!),
          trailing: ElevatedButton(
            child: Text(_device == device ? "Disconnect" : "Connect"),
            onPressed: () async {
              // _cameras = await availableCameras();
              // _cameras.forEach((element) {
              //   print(element);
              // });
              if (device.deviceName != "/dev/bus/usb/002/004") {
                if (await Permission.camera.request().isGranted) {
                  _cameras = await availableCameras();
                  _cameras.forEach((element) {
                    print(element);
                  });
                }
              } else {
                print("device");
                _connectTo(_device == device ? null : device).then((res) {
                  _getPorts();
                });
              }
            },
          )));
    });

    setState(() {
      print(_ports);
    });
  }

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Plugin example app'),
      ),
      body: Center(
          child: Column(children: <Widget>[
        Text(
            _ports.length > 0
                ? "Available Serial Ports"
                : "No serial devices available",
            style: Theme.of(context).textTheme.headline6),
        ..._ports,
        Text('Status: $_status\n'),
        Text('info: ${_port.toString()}\n'),
        ListTile(
          title: TextField(
            controller: _textController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Text To Send',
            ),
          ),
          trailing: ElevatedButton(
            child: Text("Send"),
            onPressed: _port == null
                ? null
                : () async {
                    if (_port == null) {
                      return;
                    }
                    await _port!.open();
                    _port!.inputStream!.listen((Uint8List event) {
                      print(event);
                      _port!.write(Uint8List.fromList("MID=12345".codeUnits));
                    });
                    // String data = _textController.text + "\r\n";
                    // await _port!.write(Uint8List.fromList(data.codeUnits));
                    // _textController.text = "";

                    // List<int> list = 'MID=12345'.codeUnits;
                    await _port?.open().then((value) {
                      print(dataFromPort.toString() + "------");
                      Timer(Duration(seconds: 2), () {
                        _port!.close();
                      });
                    });

                    // // if ( == "Booting system\r") {
                    // await _port!.open();
                    // await _port!
                    //     .inputStream.listen(Uint8List.fromList(list))
                    //     .then((value) async {

                    // });

                    // });

                    // }
                  },
          ),
        ),
        Text("Result Data", style: Theme.of(context).textTheme.headline6),
        ..._serialData,
        ElevatedButton(
            onPressed: () async {
              if (await Permission.camera.request().isGranted) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CamerPreview(camera: _cameras.last)));
              }
            },
            child: Text("Camera"))
      ])),
    );
  }
}
