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
  String _scanStatus = "🔄 Initializing BLE...";
  
  // Data State: 20 channels
  List<int> _currentData = List.generate(20, (index) => 0);
  final List<List<double>> _history = List.generate(20, (_) => []);
  static const int maxHistoryLen = 100;

  int _totalSamples = 0;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  String get scanStatus => _scanStatus;
  List<int> get currentData => _currentData;
  List<List<double>> get history => _history;
  int get totalSamples => _totalSamples;

  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;
  StreamSubscription? _notifySub;
  StreamSubscription? _adapterSub;
  Timer? _diagnosticTimer;

  BLEProvider() {
    _initBluetooth();
  }

  void _initBluetooth() {
    // Enable verbose logging as per Reference App
    FlutterBluePlus.setLogLevel(LogLevel.verbose);
    
    _startDiagnosticLoop();
    
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      _scanStatus = "Bluetooth: ${state.toString().split('.').last}";
      if (state == BluetoothAdapterState.on) {
        _scanStatus = "✅ Bluetooth is ON!";
      }
      notifyListeners();
    });
  }

  /// Diagnostic Loop (Replicated from Reference App)
  /// Frequently checks supported status and adapter state to "wake up" Windows hardware
  void _startDiagnosticLoop() {
    _diagnosticTimer?.cancel();
    _diagnosticTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool supported = await FlutterBluePlus.isSupported;
      var state = await FlutterBluePlus.adapterState.first;
      
      debugPrint("BLE Diagnostic: Supported=$supported, State=$state");
      
      if (state == BluetoothAdapterState.on) {
        _scanStatus = "✅ Bluetooth is ON!";
        notifyListeners();
        timer.cancel(); // Stop loop once hardware is ready
      } else {
        _scanStatus = "🔄 Waiting for Bluetooth ($state)...";
        notifyListeners();
      }
    });
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    
    // Check state before scanning
    var state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      _scanStatus = "🚫 Cannot scan: Bluetooth is ${state.toString().split('.').last}";
      notifyListeners();
      return;
    }

    _scanResults = [];
    _isScanning = true;
    _scanStatus = "📡 Scanning for Devices...";
    notifyListeners();

    try {
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        if (results.isNotEmpty) {
          _scanStatus = "✅ Found ${results.length} devices";
        }
        notifyListeners();
      }, onError: (e) => _logError("Scan Error: $e"));

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true, // Consistency with reference app
      );
      
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _logError("🚨 Scan Crash: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      _scanStatus = "Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...";
      notifyListeners();
      
      await device.connect(license: License.free);
      
      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _totalSamples = 0; // Reset counter on new connection
          for (var h in _history) h.clear(); // Clear all history lists
          _handleSuccessfulConnection(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

    } catch (e) {
      _logError("Connection Failed: $e");
      _handleDisconnect();
    }
  }

  Future<void> _handleSuccessfulConnection(BluetoothDevice device) async {
    _connectedDevice = device;
    _isConnected = true;
    _scanStatus = "Connected to ${device.platformName}";
    notifyListeners();

    try {
      // Discover Services
      List<BluetoothService> services = await device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuidStr.toLowerCase()) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == charUuidStr.toLowerCase()) {
              
              // Enable Notifications
              await c.setNotifyValue(true);
              _notifySub?.cancel();
              _notifySub = c.onValueReceived.listen((value) {
                _onDataReceived(value);
              });
            }
          }
        }
      }
    } catch (e) {
      _logError("Service Discovery Failed: $e");
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
    _totalSamples++;
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
    _adapterSub?.cancel();
    _diagnosticTimer?.cancel();
    super.dispose();
  }
}
