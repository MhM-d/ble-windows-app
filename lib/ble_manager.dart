import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

class BLELog {
  final String timestamp;
  final String device;
  final String data;
  final bool isIncoming;

  BLELog({required this.timestamp, required this.device, required this.data, this.isIncoming = true});
}

class BLEManager with ChangeNotifier {
  static const String serviceUuid = "70d146f7-815b-4768-a33a-c402551b66a6";
  static const String charUuid = "820aebea-a01a-4cb0-a29d-8e756e9aeeac";

  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  final List<BLELog> _logs = [];
  String _status = "Disconnected";

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  List<BLELog> get logs => _logs;
  String get status => _status;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      if (!await FlutterBluePlus.isSupported) {
        _log("Error", "BLE not supported on this platform");
        return;
      }

      _isScanning = true;
      _scanResults = [];
      _status = "Scanning...";
      notifyListeners();

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _log("Error", e.toString());
    } finally {
      _isScanning = false;
      _status = _connectedDevice != null ? "Connected" : "Disconnected";
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      _status = "Connecting to ${device.localName}...";
      notifyListeners();

      await device.connect();
      _connectedDevice = device;
      _status = "Connected";
      notifyListeners();

      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });

      // Discover Services
      List<BluetoothService> services = await device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == charUuid) {
              await c.setNotifyValue(true);
              _notifySub?.cancel();
              _notifySub = c.onValueReceived.listen((value) {
                _log(device.localName, value.toString());
              });
            }
          }
        }
      }
    } catch (e) {
      _log("Error", "Connection failed: $e");
      _cleanupConnection();
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanupConnection();
  }

  void _cleanupConnection() {
    _connectedDevice = null;
    _status = "Disconnected";
    _notifySub?.cancel();
    _connSub?.cancel();
    notifyListeners();
  }

  void _log(String device, String data) {
    _logs.insert(0, BLELog(
      timestamp: DateFormat('HH:mm:ss.SSS').format(DateTime.now()),
      device: device,
      data: data,
    ));
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
