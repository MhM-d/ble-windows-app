import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerProvider with ChangeNotifier {
  bool _isLogging = false;
  File? _logFile;
  String? _logPath;
  IOSink? _sink;

  bool get isLogging => _isLogging;
  String? get logPath => _logPath;

  Future<void> startLogging() async {
    if (_isLogging) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      _logPath = '${directory.path}/ble_log_$timestamp.csv';
      _logFile = File(_logPath!);
      
      _sink = _logFile!.openWrite();
      
      // Header: Timestamp + 20 Channels
      List<String> header = ['Timestamp'];
      for (int i = 1; i <= 20; i++) {
        header.add('Data $i');
      }
      _sink!.writeln(const ListToCsvConverter().convert([header]));

      _isLogging = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Logging Error: $e");
    }
  }

  void logData(List<int> data) {
    if (!_isLogging || _sink == null) return;

    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    List<dynamic> row = [timestamp];
    row.addAll(data);

    _sink!.writeln(const ListToCsvConverter().convert([row]));
  }

  Future<void> stopLogging() async {
    if (!_isLogging) return;

    await _sink?.close();
    _sink = null;
    _isLogging = false;
    notifyListeners();
  }
}
