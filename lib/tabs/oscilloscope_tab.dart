import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final history = ble.history[_selectedChannel];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHANNEL OSCILLOSCOPE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              DropdownButton<int>(
                value: _selectedChannel,
                dropdownColor: const Color(0xFF1E293B),
                items: List.generate(20, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('DATA CHANNEL ${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  setState(() => _selectedChannel = value!);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 25, top: 20, bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: true),
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
                  borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                  minX: 0,
                  maxX: BLEProvider.maxHistoryLen.toDouble(),
                  minY: 0,
                  maxY: 255,
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF10B981)]),
                      barWidth: 3,
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
        ],
      ),
    );
  }
}
