import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/reclamation.dart';
import '../services/reclamation_service.dart';
import '../services/statistics_service.dart';

class ReclamationStatisticsScreen extends StatefulWidget {
  final List<Reclamation> reclamations;

  const ReclamationStatisticsScreen({Key? key, required this.reclamations})
      : super(key: key);

  @override
  @override
  State<ReclamationStatisticsScreen> createState() =>
      _ReclamationStatisticsScreenState();
}

class _ReclamationStatisticsScreenState
    extends State<ReclamationStatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();
  late Map<String, dynamic> _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = _statsService.calculateStatistics(widget.reclamations);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reclamations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistiques'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final statusData = _statistics['statusChartData'] as List<Map<String, dynamic>>;
    final categoryData = _statistics['categoryChartData'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
            stops: const [0.0, 0.2],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 12),
                    Text(
                      '${_statistics['total']}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    Text(
                      'Total Réclamations',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Bar Chart
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Par Statut',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(statusData),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Pie Chart
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Par Catégorie',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPieChart(categoryData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final maxCount = data.fold<int>(0, (prev, item) =>
        math.max(prev, item['count'] as int));

    return Column(
      children: data.map((item) {
        final status = item['status'] as String;
        final count = item['count'] as int;
        final percentage = item['percentage'] as String;
        final colorData = _statsService.getStatusColor(status);
        final color = _getColorFromName(colorData['colorName']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '$count ($percentage%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      height: 32,
                      width: (MediaQuery.of(context).size.width - 92) *
                          (count / maxCount),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    final colors = _statsService.getCategoryColors();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: const Size(200, 200),
            painter: PieChartPainter(data: data, colors: colors),
          ),
        ),
        const SizedBox(height: 20),

        // Legend for categories
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(data.length, (index) {
            final item = data[index];
            final category = item['category'] as String;
            final count = item['count'] as int;
            final percentage = item['percentage'] as String;
            final colorData = colors[index % colors.length];
            final color = _getColorFromName(colorData['colorName']);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$category ($count - $percentage%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 30),

        // 👇 Export PDF button
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await ReclamationService().exportStatsAsPdf(
                context,
                statistics: _statistics, // ← This is the key change!
              );
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF exporté avec succès!')),
              );
            } catch (e) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exporter en PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
        ),
      ],
    );
  }


  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue[700]!;
      case 'green':
        return Colors.green[600]!;
      case 'orange':
        return Colors.orange[700]!;
      case 'red':
        return Colors.red[600]!;
      case 'purple':
        return Colors.purple[600]!;
      case 'pink':
        return Colors.pink[600]!;
      case 'teal':
        return Colors.teal[600]!;
      case 'indigo':
        return Colors.indigo[600]!;
      case 'cyan':
        return Colors.cyan[700]!;
      case 'lime':
        return Colors.lime[700]!;
      case 'amber':
        return Colors.amber[700]!;
      case 'deepPurple':
        return Colors.deepPurple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> colors;

  PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;

    final total = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));

    for (int i = 0; i < data.length; i++) {
      final count = data[i]['count'] as int;
      final sweepAngle = (count / total) * 2 * math.pi;
      final colorData = colors[i % colors.length];
      final color = _getColorFromName(colorData['colorName']);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw white circle in center for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue[700]!;
      case 'purple':
        return Colors.purple[600]!;
      case 'pink':
        return Colors.pink[600]!;
      case 'orange':
        return Colors.orange[700]!;
      case 'teal':
        return Colors.teal[600]!;
      case 'indigo':
        return Colors.indigo[600]!;
      case 'cyan':
        return Colors.cyan[700]!;
      case 'lime':
        return Colors.lime[700]!;
      case 'amber':
        return Colors.amber[700]!;
      case 'deepPurple':
        return Colors.deepPurple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}