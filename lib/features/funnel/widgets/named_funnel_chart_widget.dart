import 'package:flutter/material.dart';
import '../../../core/models/analytics_models.dart';
import 'funnel_chart_widget.dart';

class NamedFunnelChartWidget extends StatelessWidget {
  final NamedFunnelData funnelData;
  final bool isMobile;

  const NamedFunnelChartWidget({
    super.key,
    required this.funnelData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // Convert NamedFunnelData to FunnelData for rendering
    // Since FunnelChartWidget already handles the visualization
    final adaptedFunnelData = FunnelData(
      steps: funnelData.steps,
      overallConversion: funnelData.overallConversion,
    );

    return Column(
      children: [
        // Funnel Name Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.filter_alt,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'FUNNEL: ',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                funnelData.funnelName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ),

        // Use existing FunnelChartWidget for visualization
        FunnelChartWidget(
          funnelData: adaptedFunnelData,
          isMobile: isMobile,
        ),
      ],
    );
  }
}
