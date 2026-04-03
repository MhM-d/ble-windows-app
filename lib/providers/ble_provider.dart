import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEProvider with ChangeNotifier {
  static const String serviceUuidStr = "70d146f7-815b-4768-a33a-c402551b66a6";
  static const String charUuidStr = "820aebea-a01a-4cb0-a29d-8e756e9aeeac";

  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  String _scanStatus = "Ready to Scan";
  
  // Data State: 20 channels
  List<int> _currentData = List.generate(20, (index) => 0);
  final List<List<double>> _history = List.generate(20, (_) => []);
  static const int maxHistoryLen = 100;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  String get scanStatus => _scanStatus;
  List<int> get currentData => _currentData;
  List<List<double>> get history => _history;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  Future<void> startScan() async {
    if (_isScanning) return;
    _scanStatus = "Checking Support...";
    notifyListeners();

    try {
      if (!await FlutterBluePlus.isSupported) {
        _scanStatus = "BLE not supported";
        notifyListeners();
        return;
      }

      _isScanning = true;
      _scanResults = [];
      _scanStatus = "Scanning...";
      notifyListeners();

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      }, onError: (e) => _logError("Scan: $e"));

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _logError("Failed to Scan: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      _scanStatus = "Connecting to ${device.localName}...";
      notifyListeners();
      
      await device.connect();
      _connectedDevice = device;
      _isConnected = true;
      _scanStatus = "Connected";
      notifyListeners();

      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Discover Services
      List<BluetoothService> services = await device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuidStr.toLowerCase()) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == charUuidStr.toLowerCase()) {
              await c.setNotifyValue(true);
              _notifySub?.cancel();
              _notifySub = c.onValueReceived.listen((value) => _onDataReceived(value));
            }
          }
        }
      }
    } catch (e) {
      _logError("Connection Failed: $e");
      _handleDisconnect();
    }
  }

  void _onDataReceived(List<int> data) {
    if (data.isEmpty) return;
    List<int> padded = List.from(data);
    while (padded.length < 20) padded.add(0);
    _currentData = padded.take(20).toList();

    for (int i = 0; i < 20; i++) {
      _history[i].add(_currentData[i].toDouble());
      if (_history[i].length > maxHistoryLen) _history[i].removeAt(0);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectedDevice = null;
    _connSub?.cancel();
    _notifySub?.cancel();
    _scanStatus = "Disconnected";
    notifyListeners();
  }

  void _logError(String msg) {
    _scanStatus = msg;
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
