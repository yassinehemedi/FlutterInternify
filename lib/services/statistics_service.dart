import '../models/reclamation.dart';

class StatisticsService {
  // Calculate statistics from list of reclamations
  Map<String, dynamic> calculateStatistics(List<Reclamation> reclamations) {
    if (reclamations.isEmpty) {
      return {
        'total': 0,
        'byStatus': {},
        'byCategory': {},
        'statusChartData': [],
        'categoryChartData': [],
      };
    }

    // Count by status
    Map<String, int> statusCount = {};
    for (var reclamation in reclamations) {
      statusCount[reclamation.status] = (statusCount[reclamation.status] ?? 0) + 1;
    }

    // Count by category
    Map<String, int> categoryCount = {};
    for (var reclamation in reclamations) {
      categoryCount[reclamation.category] = (categoryCount[reclamation.category] ?? 0) + 1;
    }

    // Prepare data for bar chart (status)
    List<Map<String, dynamic>> statusChartData = statusCount.entries
        .map((entry) => {
      'status': entry.key,
      'count': entry.value,
      'percentage': (entry.value / reclamations.length * 100).toStringAsFixed(1),
    })
        .toList();

    // Prepare data for pie chart (category)
    List<Map<String, dynamic>> categoryChartData = categoryCount.entries
        .map((entry) => {
      'category': entry.key,
      'count': entry.value,
      'percentage': (entry.value / reclamations.length * 100).toStringAsFixed(1),
    })
        .toList();

    // Sort by count (descending)
    statusChartData.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    categoryChartData.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return {
      'total': reclamations.length,
      'byStatus': statusCount,
      'byCategory': categoryCount,
      'statusChartData': statusChartData,
      'categoryChartData': categoryChartData,
    };
  }

  // Get color for status
  Map<String, dynamic> getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return {'colorName': 'blue', 'opacity': 0.8};
      case 'terminée':
        return {'colorName': 'green', 'opacity': 0.8};
      case 'en attente':
        return {'colorName': 'orange', 'opacity': 0.8};
      case 'rejetée':
        return {'colorName': 'red', 'opacity': 0.8};
      default:
        return {'colorName': 'grey', 'opacity': 0.8};
    }
  }

  // Get color for category (for pie chart)
  List<Map<String, dynamic>> getCategoryColors() {
    return [
      {'colorName': 'blue', 'shade': 700},
      {'colorName': 'purple', 'shade': 600},
      {'colorName': 'pink', 'shade': 600},
      {'colorName': 'orange', 'shade': 700},
      {'colorName': 'teal', 'shade': 600},
      {'colorName': 'indigo', 'shade': 600},
      {'colorName': 'cyan', 'shade': 700},
      {'colorName': 'lime', 'shade': 700},
      {'colorName': 'amber', 'shade': 700},
      {'colorName': 'deepPurple', 'shade': 600},
    ];
  }

  // Format percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Get summary text for quick view
  String getSummaryText(Map<String, dynamic> statistics) {
    final byStatus = statistics['byStatus'] as Map<String, int>;
    final enCours = byStatus['En Cours'] ?? 0;
    final terminee = byStatus['Terminée'] ?? 0;

    return '$enCours En Cours | $terminee Terminée${byStatus.length > 2 ? ' | +${byStatus.length - 2}' : ''}';
  }

  // Get unique statuses from reclamations
  List<String> getUniqueStatuses(List<Reclamation> reclamations) {
    final statuses = reclamations.map((r) => r.status).toSet().toList();
    statuses.sort();
    return statuses;
  }

  // Get unique categories from reclamations
  List<String> getUniqueCategories(List<Reclamation> reclamations) {
    final categories = reclamations.map((r) => r.category).toSet().toList();
    categories.sort();
    return categories;
  }
}