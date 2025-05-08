import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class UnifiedRobotControlPage extends StatefulWidget {
  const UnifiedRobotControlPage({super.key});

  @override
  State<UnifiedRobotControlPage> createState() => _UnifiedRobotControlPageState();
}

class _UnifiedRobotControlPageState extends State<UnifiedRobotControlPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  bool isConnecting = false;
  bool isConnected = false;

  void scanAndConnect() async {
    setState(() => isConnecting = true);

    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "HC-05" || r.device.name == "HC-06") {
          await flutterBlue.stopScan();
          try {
            await r.device.connect();
          } catch (e) {
            if (e.toString().contains('already connected')) {
              // ignore
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Bağlantı hatası: $e")),
              );
              return;
            }
          }

          List<BluetoothService> services = await r.device.discoverServices();
          for (var service in services) {
            for (var characteristic in service.characteristics) {
              if (characteristic.properties.write) {
                setState(() {
                  connectedDevice = r.device;
                  targetCharacteristic = characteristic;
                  isConnected = true;
                  isConnecting = false;
                });
                return;
              }
            }
          }
        }
      }
    });
  }

  void sendCommand(String command) async {
    if (targetCharacteristic != null) {
      await targetCharacteristic!.write(command.codeUnits);
    }
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }

  Widget buildControlButton(String label, String command) {
    return ElevatedButton(
      onPressed: isConnected ? () => sendCommand(command) : null,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Robot Arm Control")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isConnecting ? null : scanAndConnect,
              child: Text(isConnected ? "Bağlı: ${connectedDevice!.name}" : "Scan & Connect"),
            ),
            const SizedBox(height: 20),
            if (isConnected)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildControlButton("↑", "U"), // Up
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildControlButton("←", "L"), // Left
                      const SizedBox(width: 10),
                      buildControlButton("Stop", "S"), // Stop
                      const SizedBox(width: 10),
                      buildControlButton("→", "R"), // Right
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildControlButton("↓", "D"), // Down
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildControlButton("Grip Open", "O"),
                      const SizedBox(width: 10),
                      buildControlButton("Grip Close", "C"),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}