import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/ble_provider.dart';

class OscilloscopeView extends StatefulWidget {
  const OscilloscopeView({super.key});

  @override
  State<OscilloscopeView> createState() => _OscilloscopeViewState();
}

class _OscilloscopeViewState extends State<OscilloscopeView> {
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
                  setState(() {
                    _selectedChannel = value!;
                  });
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
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.white10, strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.white10, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 50,
                        getTitlesWidget: bottomTitleWidgets,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        getTitlesWidget: leftTitleWidgets,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: BLEProvider.maxHistoryLen.toDouble(),
                  minY: 0,
                  maxY: 255,
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF38BDF8).withOpacity(0.3),
                            const Color(0xFF10B981).withOpacity(0.0),
                          ],
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIndicator('MIN', history.isEmpty ? '0' : history.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)),
              _buildIndicator('MAX', history.isEmpty ? '0' : history.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)),
              _buildIndicator('AVG', history.isEmpty ? '0' : (history.reduce((a, b) => a + b) / history.length).toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

Widget leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54);
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(value.toInt().toString(), style: style, textAlign: TextAlign.left),
  );
}

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54);
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text((value - BLEProvider.maxHistoryLen).toInt().toString(), style: style),
  );
}
