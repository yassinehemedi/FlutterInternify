import 'package:flutter/material.dart';
import '../models/reclamation.dart';
import '../services/reclamation_service.dart';
import '../services/statistics_service.dart';
import '../services/search_service.dart';
import 'reclamation_form_screen.dart';
import 'reclamation_statistics_screen.dart';

class ReclamationsListScreen extends StatefulWidget {
  final int userId;

  const ReclamationsListScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<ReclamationsListScreen> createState() => _ReclamationsListScreenState();
}

class _ReclamationsListScreenState extends State<ReclamationsListScreen> {
  final ReclamationService _service = ReclamationService();
  final StatisticsService _statsService = StatisticsService();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  List<Reclamation> _reclamations = [];
  List<Reclamation> _filteredReclamations = [];
  bool _isLoading = true;
  String? _selectedStatus;
  String? _selectedCategory;
  List<String> _availableStatuses = ['Tous'];
  List<String> _availableCategories = ['Toutes'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'Tous';
    _selectedCategory = 'Toutes';
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getReclamationsByUserId(widget.userId);
    setState(() {
      _reclamations = data;
      _availableStatuses = ['Tous', ..._statsService.getUniqueStatuses(data)];
      _availableCategories = ['Toutes', ..._statsService.getUniqueCategories(data)];
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredReclamations = _searchService.filterReclamations(
        allReclamations: _reclamations,
        searchQuery: _searchController.text,
        statusFilter: _selectedStatus,
        categoryFilter: _selectedCategory,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'Tous';
      _selectedCategory = 'Toutes';
      _applyFilters();
    });
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // 🎨 NEW: Get Priority Color
  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 🎨 NEW: Get Priority Icon
  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.flag;
      case 'low':
        return Icons.flag_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  // 🎨 NEW: Get Sentiment Icon
  IconData _getSentimentIcon(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_satisfied_alt;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // 🎨 NEW: Get Sentiment Color
  Color _getSentimentColor(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistics = _statsService.calculateStatistics(_reclamations);
    final hasActiveFilters = _searchService.hasActiveFilters(
      _searchController.text,
      _selectedStatus,
      _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réclamations'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_reclamations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReclamationStatisticsScreen(
                      reclamations: _reclamations,
                    ),
                  ),
                );
              },
              tooltip: 'Voir les statistiques',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _reclamations.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.blue[300]),
              const SizedBox(height: 16),
              Text(
                'Aucune réclamation',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Appuyez sur + pour ajouter',
                style: TextStyle(color: Colors.blue[700]),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Statistics Summary Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReclamationStatisticsScreen(
                          reclamations: _reclamations,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statsService.getSummaryText(statistics),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${statistics['total']} réclamations',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre, description...',
                  prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                ),
              ),
            ),

            // Status Filter Chips
            if (_availableStatuses.length > 1)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableStatuses.length,
                  itemBuilder: (context, index) {
                    final status = _availableStatuses[index];
                    final isSelected = status == _selectedStatus;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = status;
                            _applyFilters();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[700],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue[900] : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Category Filter Chips
            if (_availableCategories.length > 1)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableCategories.length,
                  itemBuilder: (context, index) {
                    final category = _availableCategories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                            _applyFilters();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.purple[100],
                        checkmarkColor: Colors.purple[700],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.purple[900] : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.purple[700]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Result Count and Clear Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchService.getResultCountMessage(
                      _filteredReclamations.length,
                      _searchController.text.isNotEmpty ? _searchController.text : null,
                    ),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Effacer les filtres'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                ],
              ),
            ),

            // Reclamations List or Empty State
            Expanded(
              child: _filteredReclamations.isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchService.getEmptyStateMessage(
                          _searchController.text.isNotEmpty ? _searchController.text : null,
                          hasActiveFilters,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réinitialiser les filtres'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filteredReclamations.length,
                itemBuilder: (context, index) {
                  final reclamation = _filteredReclamations[index];
                  final statusColor = _getColorFromName(
                    _service.getStatusColorName(reclamation.status),
                  );

                  // 🎨 Get priority and sentiment colors
                  final priorityColor = _getPriorityColor(reclamation.priority);
                  final sentimentColor = _getSentimentColor(reclamation.sentiment);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16, top: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      // 🎨 NEW: Add colored border for high priority
                      side: reclamation.priority?.toLowerCase() == 'high'
                          ? BorderSide(color: Colors.red.shade300, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReclamationFormScreen(
                              userId: widget.userId,
                              reclamation: reclamation,
                            ),
                          ),
                        );
                        if (result == true) _loadData();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🎨 TITLE + STATUS ROW
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reclamation.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    reclamation.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // DESCRIPTION
                            Text(
                              reclamation.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 🎨 NEW: PRIORITY & SENTIMENT BADGES
                            if (reclamation.priority != null || reclamation.sentiment != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple[50]!,
                                      Colors.blue[50]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.purple[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // 🎨 PRIORITY BADGE
                                    if (reclamation.priority != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: priorityColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getPriorityIcon(reclamation.priority),
                                                size: 18,
                                                color: priorityColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Priorité',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  reclamation.priority!.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: priorityColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                    // 🎨 DIVIDER
                                    if (reclamation.priority != null && reclamation.sentiment != null)
                                      Container(
                                        height: 40,
                                        width: 1,
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        color: Colors.grey[300],
                                      ),

                                    // 🎨 SENTIMENT BADGE
                                    if (reclamation.sentiment != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: sentimentColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getSentimentIcon(reclamation.sentiment),
                                                size: 18,
                                                color: sentimentColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sentiment',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  reclamation.sentiment!.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: sentimentColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // CATEGORY + DATE
                            Row(
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 16, color: Colors.blue[600]),
                                const SizedBox(width: 4),
                                Text(
                                  reclamation.category,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _service.formatDate(reclamation.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ACTION BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReclamationFormScreen(
                                              userId: widget.userId,
                                              reclamation: reclamation,
                                            ),
                                      ),
                                    );
                                    if (result == true) _loadData();
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Modifier'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirmer la suppression'),
                                        content: const Text(
                                            'Êtes-vous sûr de vouloir supprimer cette réclamation ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Annuler'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final result = await _service
                                          .removeReclamation(reclamation.id!);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(result['message']),
                                            backgroundColor:
                                            result['success']
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        );
                                        if (result['success']) _loadData();
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Supprimer'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReclamationFormScreen(userId: widget.userId),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}