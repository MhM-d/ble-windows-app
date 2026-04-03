import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/ble_provider.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEVICE DISCOVERY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    ble.scanStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ble.scanStatus.contains("OFF") || ble.scanStatus.contains("error")
                          ? Colors.redAccent
                          : Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: ble.isScanning ? ble.stopScan : ble.startScan,
                icon: ble.isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(ble.isScanning ? 'STOPPING...' : 'START SCAN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ble.isScanning ? Colors.redAccent : Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: ble.scanResults.length,
              itemBuilder: (context, index) {
                final result = ble.scanResults[index];
                final device = result.device;
                final name = device.name.isNotEmpty ? device.name : 'Unknown Device';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        child: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(device.id.id, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text('${result.rssi} dBm', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Signal', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: ble.isConnected && ble.connectedDevice?.id == device.id
                            ? ble.disconnect
                            : () => ble.connectToDevice(device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ble.isConnected && ble.connectedDevice?.id == device.id
                              ? Colors.redAccent.withOpacity(0.2)
                              : Colors.greenAccent.withOpacity(0.2),
                          foregroundColor: ble.isConnected && ble.connectedDevice?.id == device.id
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          side: BorderSide(
                            color: ble.isConnected && ble.connectedDevice?.id == device.id
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                        ),
                        child: Text(ble.isConnected && ble.connectedDevice?.id == device.id
                            ? 'DISCONNECT'
                            : 'CONNECT'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
