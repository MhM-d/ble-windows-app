import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/ble_provider.dart';

class ChartConfig {
  int channelIndex;
  double yZoom;
  double xZoom;
  double yOffset;
  bool isPanMode;
  final Color primaryColor;
  final Color accentColor;

  ChartConfig({
    required this.channelIndex,
    this.yZoom = 1.0,
    this.xZoom = 1.0,
    this.yOffset = 0.0,
    this.isPanMode = false,
    required this.primaryColor,
    required this.accentColor,
  });
}

class OscilloscopeTab extends StatefulWidget {
  const OscilloscopeTab({super.key});

  @override
  State<OscilloscopeTab> createState() => _OscilloscopeTabState();
}

class _OscilloscopeTabState extends State<OscilloscopeTab> {
  final List<ChartConfig> _configs = [
    ChartConfig(
      channelIndex: 0, 
      primaryColor: const Color(0xFFFF5252), // Red Accent
      accentColor: const Color(0xFFFF8A80),
    ),
    ChartConfig(
      channelIndex: 1, 
      primaryColor: const Color(0xFF448AFF), // Blue Accent
      accentColor: const Color(0xFF82B1FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 15),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TelemetryChartCard(
                    config: _configs[0],
                    onUpdate: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: TelemetryChartCard(
                    config: _configs[1],
                    onUpdate: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA MONITOR',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class TelemetryChartCard extends StatelessWidget {
  final ChartConfig config;
  final VoidCallback onUpdate;

  const TelemetryChartCard({
    super.key,
    required this.config,
    required this.onUpdate,
  });

  void _adjustYZoom(double delta) {
    config.yZoom = (config.yZoom + delta).clamp(1.0, 20.0);
    onUpdate();
  }

  void _adjustXZoom(double delta) {
    config.xZoom = (config.xZoom + delta).clamp(1.0, 10.0);
    onUpdate();
  }

  void _togglePanMode() {
    config.isPanMode = !config.isPanMode;
    if (!config.isPanMode) config.yOffset = 0.0; // Snap back to auto-scale logic
    onUpdate();
  }

  void _handlePanUpdate(DragUpdateDetails details, double chartHeight, double currentRange) {
    if (!config.isPanMode) return;
    // Map vertical pixel delta to chart units: deltaY in pixels * (visibleRange / widgetHeight)
    // Drag data down (pos pixels) -> move view down (dec axis values)
    double deltaUnits = details.delta.dy * (currentRange / chartHeight);
    config.yOffset -= deltaUnits;
    onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final history = ble.history[config.channelIndex];
    final totalSamples = ble.totalSamples;

    // Calculate Y-scale based on default [-100, 100] or expanded data range
    double minY = -100;
    double maxY = 100;
    
    if (history.isNotEmpty) {
      double minData = history.reduce((a, b) => a < b ? a : b);
      double maxData = history.reduce((a, b) => a > b ? a : b);
      
      // Expand thresholds if data is outside [-100, 100]
      if (minData < -100) minY = minData - 20; // Some extra room
      if (maxData > 100) maxY = maxData + 20;

      // Adjust for Y Zoom
      if (config.yZoom > 1.0) {
        double center = (minY + maxY) / 2;
        double zoomedRange = (maxY - minY) / config.yZoom;
        minY = center - (zoomedRange / 2);
        maxY = center + (zoomedRange / 2);
      }
    }
    
    // Add manual Y-axis panning offset
    minY += config.yOffset;
    maxY += config.yOffset;
    
    // Fixed 100-unit window sliding logic
    // Start with 0 to 100, then slide to (totalSamples - 100) to totalSamples
    double maxX = totalSamples.toDouble() > 100 ? totalSamples.toDouble() : 100.0;
    double minX = maxX - 100.0;

    // Generate spots using absolute sample indices
    int startIdx = totalSamples - history.length;
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot((startIdx + i).toDouble(), history[i]));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              _buildControlBar(context),
              const SizedBox(height: 10),
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      if (RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft) || 
                          RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlRight)) {
                        _adjustXZoom(pointerSignal.scrollDelta.dy < 0 ? 0.5 : -0.5);
                      } else {
                        _adjustYZoom(pointerSignal.scrollDelta.dy < 0 ? 0.5 : -0.5);
                      }
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onVerticalDragUpdate: (details) => _handlePanUpdate(details, constraints.maxHeight, maxY - minY),
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
                                  reservedSize: 22,
                                  interval: 20, // Consistent interval for readability
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(value.toInt().toString(), 
                                        style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4))),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38, // Slightly more space for decimals
                                  interval: (maxY - minY) / 6, // Evenly space ticks across the full range
                                  getTitlesWidget: (value, meta) => SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(value.toStringAsFixed(1), 
                                      style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4))),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10, width: 1)),
                            clipData: const FlClipData.all(), // Fix visual crossing out of bounds
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                gradient: LinearGradient(colors: [config.primaryColor, config.accentColor]),
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [config.primaryColor.withOpacity(0.2), Colors.transparent],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                        ),
                      );
                    }
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: config.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: config.primaryColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.2), 
                    blurRadius: 10, 
                    spreadRadius: -2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Text(
                'CH ${config.channelIndex + 1}',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: config.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: config.channelIndex,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                isDense: true,
                items: List.generate(20, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('CHANNEL ${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  config.channelIndex = value!;
                  onUpdate();
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildZoomControl('Y', () => _adjustYZoom(0.5), () => _adjustYZoom(-0.5)),
            const SizedBox(width: 8),
            _panBtn(),
            const SizedBox(width: 8),
            _buildZoomControl('X', () => _adjustXZoom(0.5), () => _adjustXZoom(-0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomControl(String label, VoidCallback onPlus, VoidCallback onMinus) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 15,
            child: Center(
              child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38)),
            ),
          ),
          _zoomBtn(Icons.remove, onMinus),
          _zoomBtn(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 12),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      color: Colors.white60,
      splashRadius: 12,
    );
  }

  Widget _panBtn() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: config.isPanMode ? config.primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.isPanMode ? config.primaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(config.isPanMode ? Icons.pan_tool_rounded : Icons.pan_tool_outlined, size: 12),
        onPressed: _togglePanMode,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        color: config.isPanMode ? config.primaryColor : Colors.white60,
        splashRadius: 12,
        tooltip: 'Pan Mode (Drag Y-Axis)',
      ),
    );
  }
}
