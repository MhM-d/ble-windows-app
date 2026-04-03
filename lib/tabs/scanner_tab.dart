import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../providers/logger_provider.dart';

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final logger = context.watch<LoggerProvider>();

    return Row(
      children: [
        // LEFT: Scanner
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SCANNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ElevatedButton(
                      onPressed: ble.isScanning ? null : ble.startScan,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
                      child: Text(ble.isScanning ? 'SCANNING...' : 'START SCAN'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: ble.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = ble.scanResults[index];
                      final name = result.device.localName.isEmpty ? 'Unknown' : result.device.localName;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth_rounded, color: Color(0xFF38BDF8)),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(result.device.id.toString(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                        trailing: Text('${result.rssi} dBm'),
                        onTap: () => ble.connect(result.device),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // RIGHT: Logging
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATA LOGGER (CSV)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: logger.isLogging ? null : logger.startLogging,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('START LOGGING'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2), foregroundColor: Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: logger.isLogging ? logger.stopLogging : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('STOP LOGGING'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('LOG STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
                const SizedBox(height: 8),
                Text(logger.isLogging ? 'ACTIVE: Writing to ${logger.logPath?.split('/').last}' : 'IDLE: Ready to log',
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
