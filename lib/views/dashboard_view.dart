import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../providers/logger_provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final logger = context.watch<LoggerProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REAL-TIME CHANNELS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              ElevatedButton.icon(
                onPressed: ble.isConnected
                    ? (logger.isLogging
                        ? logger.stopLogging
                        : () => logger.startLogging(
                              List.generate(20, (i) => 'Data${i + 1}'),
                            ))
                    : null,
                icon: Icon(
                  logger.isLogging ? Icons.stop_circle_rounded : Icons.save_alt_rounded,
                  color: logger.isLogging ? Colors.redAccent : Colors.white,
                ),
                label: Text(
                  logger.isLogging ? 'STOP LOGGING' : 'START LOGGING',
                  style: TextStyle(
                    color: logger.isLogging ? Colors.redAccent : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: logger.isLogging
                      ? Colors.redAccent.withOpacity(0.1)
                      : Colors.blueAccent.withOpacity(0.1),
                  side: BorderSide(
                    color: logger.isLogging ? Colors.redAccent : Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                final value = ble.currentData[index];
                
                // Logging occurs here if active
                if (logger.isLogging && index == 0) {
                  // Only log once per data update
                  logger.logData(ble.currentData);
                }

                return DataCard(
                  title: 'DATA CHANNEL ${index + 1}',
                  value: value.toString(),
                  color: Colors.blueAccent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DataCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const DataCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
