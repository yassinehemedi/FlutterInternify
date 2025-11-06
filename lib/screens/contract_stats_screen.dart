import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/contract_model.dart';
import '../theme/app_theme.dart';

class ContractStatsScreen extends StatelessWidget {
  final List<Contract> contracts;

  const ContractStatsScreen({super.key, required this.contracts});

  Map<String, int> _getStatusCounts() {
    final Map<String, int> counts = {
      'Pending': 0,
      'Signed': 0,
      'Active': 0,
      'Expired': 0,
    };

    for (var contract in contracts) {
      counts[contract.status] = (counts[contract.status] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, int> _getContractTypeCounts() {
    final Map<String, int> counts = {};

    for (var contract in contracts) {
      if (contract.contractType != null) {
        counts[contract.contractType!] = (counts[contract.contractType!] ?? 0) + 1;
      }
    }

    return counts;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Signed':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      case 'Active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Color> _getTypeColors() {
    return [
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();
    final typeCounts = _getContractTypeCounts();
    final totalContracts = contracts.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          'Contract Statistics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: contracts.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Contracts Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Contracts',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalContracts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Distribution
            const Text(
              'Status Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: _buildStatusSections(statusCounts),
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegend(statusCounts, true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contract Type Distribution
            if (typeCounts.isNotEmpty) ...[
              const Text(
                'Contract Type Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: _buildTypeSections(typeCounts),
                          centerSpaceRadius: 60,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLegend(typeCounts, false),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No statistics available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some contracts to see statistics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildStatusSections(Map<String, int> counts) {
    final total = counts.values.fold(0, (sum, count) => sum + count);

    return counts.entries.where((entry) => entry.value > 0).map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: _getStatusColor(entry.key),
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildTypeSections(Map<String, int> counts) {
    final total = counts.values.fold(0, (sum, count) => sum + count);
    final colors = _getTypeColors();

    return counts.entries.toList().asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: colors[index % colors.length],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> counts, bool isStatus) {
    final colors = isStatus ? null : _getTypeColors();

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: counts.entries.toList().asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        final color = isStatus
            ? _getStatusColor(entry.key)
            : colors![index % colors.length];

        return Row(
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
              '${entry.key}: ${entry.value}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}