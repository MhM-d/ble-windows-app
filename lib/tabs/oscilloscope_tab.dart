import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/ble_provider.dart';

class OscilloscopeTab extends StatefulWidget {
  const OscilloscopeTab({super.key});

  @override
  State<OscilloscopeTab> createState() => _OscilloscopeTabState();
}

class _OscilloscopeTabState extends State<OscilloscopeTab> {
  int _selectedChannel = 0;
  double _yZoom = 1.0; // Vertical multiplication
  double _xZoom = 1.0; // Horizontal window (1.0 = 100 points, 2.0 = 50 points, etc.)

  void _adjustYZoom(double delta) {
    setState(() {
      _yZoom = (_yZoom + delta).clamp(1.0, 20.0);
    });
  }

  void _adjustXZoom(double delta) {
    setState(() {
      _xZoom = (_xZoom + delta).clamp(1.0, 10.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final history = ble.history[_selectedChannel];

    // Calculate Y-scale based on zoom
    double maxY = 255 / _yZoom;
    
    // Calculate X-scale based on zoom
    double windowSize = BLEProvider.maxHistoryLen / _xZoom;
    double minX = BLEProvider.maxHistoryLen - windowSize;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATA MONITOR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'REAL-TIME TELEMETRY VISUALIZER',
                    style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  // Y-Zoom Controls
                  _buildZoomControls(
                    label: 'Y', 
                    onPlus: () => _adjustYZoom(0.5), 
                    onMinus: () => _adjustYZoom(-0.5),
                  ),
                  const SizedBox(width: 15),
                  // X-Zoom Controls
                  _buildZoomControls(
                    label: 'X', 
                    onPlus: () => _adjustXZoom(0.5), 
                    onMinus: () => _adjustXZoom(-0.5),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<int>(
                    value: _selectedChannel,
                    dropdownColor: const Color(0xFF1E293B),
                    items: List.generate(20, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text('CHANNEL ${index + 1}'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() => _selectedChannel = value!);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // If Ctrl is pressed, zoom X (Time)
                  if (RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft) || 
                      RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlRight)) {
                    _adjustXZoom(pointerSignal.scrollDelta.dy < 0 ? 0.5 : -0.5);
                  } else {
                    // Default zoom Y (Values)
                    _adjustYZoom(pointerSignal.scrollDelta.dy < 0 ? 0.5 : -0.5);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.only(right: 25, top: 20, bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                      getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text((value - BLEProvider.maxHistoryLen).toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10, width: 1)),
                    minX: minX,
                    maxX: BLEProvider.maxHistoryLen.toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF10B981)]),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [const Color(0xFF38BDF8).withOpacity(0.2), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls({required String label, required VoidCallback onPlus, required VoidCallback onMinus}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
          const SizedBox(width: 8),
          _zoomButton(Icons.remove, onMinus),
          _zoomButton(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      color: Colors.white70,
      splashRadius: 16,
    );
  }
}
