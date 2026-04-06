import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ble_provider.dart';
import 'providers/logger_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/oscilloscope_tab.dart';
import 'tabs/scanner_tab.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BLEProvider()),
        ChangeNotifierProvider(create: (_) => LoggerProvider()),
      ],
      child: const BLEApp(),
    ),
  );
}

class BLEApp extends StatelessWidget {
  const BLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced BLE Monitor',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF38BDF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
      ),
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final logger = context.watch<LoggerProvider>();

    // Pass data to logger if active
    if (logger.isLogging && ble.isConnected) {
      logger.logData(ble.currentData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE MONITOR DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'DASHBOARD'),
            Tab(icon: Icon(Icons.show_chart_rounded), text: 'DATA MONITOR'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'SCANNER & LOG'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            DashboardTab(),
            OscilloscopeTab(),
            ScannerTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppStatus(
        isConnected: ble.isConnected,
        isLogging: logger.isLogging,
        deviceName: ble.connectedDevice?.localName ?? 'No Device',
      ),
    );
  }
}

class BottomAppStatus extends StatelessWidget {
  final bool isConnected;
  final bool isLogging;
  final String deviceName;

  const BottomAppStatus({
    super.key,
    required this.isConnected,
    required this.isLogging,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  boxShadow: isConnected ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 8)] : [],
                ),
              ),
              const SizedBox(width: 8),
              Text(isConnected ? 'CONNECTED: $deviceName' : 'DISCONNECTED', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              if (isLogging) const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(isLogging ? 'LOGGING ACTIVE' : 'LOGGING IDLE', 
                  style: TextStyle(fontSize: 11, color: isLogging ? Colors.redAccent : Colors.white54, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
