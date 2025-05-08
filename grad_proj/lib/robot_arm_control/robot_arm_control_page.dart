import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sizer/sizer.dart';

import '../constants.dart'; // Eğer kullanıyorsan bu gerekli


class RobotArmControlPage extends StatefulWidget {
  const RobotArmControlPage({Key? key}) : super(key: key);

  @override
  _RobotArmControlPageState createState() => _RobotArmControlPageState();
}

class _RobotArmControlPageState extends State<RobotArmControlPage> {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;

  void _startScan() {
    _flutterBlue.startScan(timeout: const Duration(seconds: 4));
    _flutterBlue.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.name == 'ROBOT_ARM_BT') {
          _flutterBlue.stopScan();
          _connect(r.device);
          break;
        }
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    await device.connect();
    final services = await device.discoverServices();
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb') {
          setState(() {
            _device = device;
            _char = c;
          });
        }
      }
    }
  }

  void _send(String cmd) {
    if (_char != null) {
      final bytes = Uint8List.fromList(utf8.encode(cmd));
      _char!.write(bytes, withoutResponse: true);
    }
  }

  @override
  void dispose() {
    _device?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robotic Control')),
      body: Center(
        child: _device == null
            ? Center(
          child: InkResponse(
            onTap: _startScan,
            child: SizedBox(
              width: 40.w,
              height: 9.h,
              child: Card(
                color: kPrimaryColor,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(3.h),
                ),
                child: Center(
                  child: Text(
                    'Scan & Connect',
                    style: TextStyle(
                      color: kScaffoldColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text('Robotic Arm', style: TextStyle(fontSize: 18)),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                      onPressed: () => _send('L'),
                      child: const Text('Left')),
                  ElevatedButton(
                      onPressed: () => _send('R'),
                      child: const Text('Right')),
                  ElevatedButton(
                      onPressed: () => _send('U'),
                      child: const Text('Up')),
                  ElevatedButton(
                      onPressed: () => _send('D'),
                      child: const Text('Down')),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Tekerlek', style: TextStyle(fontSize: 18)),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                      onPressed: () => _send('F'),
                      child: const Text('Forward')),
                  ElevatedButton(
                      onPressed: () => _send('B'),
                      child: const Text('Back')),
                  ElevatedButton(
                      onPressed: () => _send('S'),
                      child: const Text('Stop')),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
