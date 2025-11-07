import '../models/reclamation.dart';

class SearchService {
  // Filter reclamations based on search query and filters
  List<Reclamation> filterReclamations({
    required List<Reclamation> allReclamations,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
  }) {
    List<Reclamation> filtered = List.from(allReclamations);

    // Apply search query filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = _normalizeString(searchQuery.toLowerCase());

      filtered = filtered.where((reclamation) {
        final title = _normalizeString(reclamation.title.toLowerCase());
        final description = _normalizeString(reclamation.description.toLowerCase());
        final category = _normalizeString(reclamation.category.toLowerCase());
        final status = _normalizeString(reclamation.status.toLowerCase());

        return title.contains(normalizedQuery) ||
            description.contains(normalizedQuery) ||
            category.contains(normalizedQuery) ||
            status.contains(normalizedQuery);
      }).toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter != 'Tous') {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    // Apply category filter
    if (categoryFilter != null && categoryFilter != 'Toutes') {
      filtered = filtered.where((r) => r.category == categoryFilter).toList();
    }

    return filtered;
  }

  // Normalize French characters (remove accents)
  String _normalizeString(String input) {
    const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÑÇ';
    const withoutAccents = 'aaaaaaeeeeiiiioooooouuuuyyncAAAAAEEEEIIIIOOOOOUUUUYYNC';

    String result = input;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  // Get search result count message
  String getResultCountMessage(int count, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return '$count réclamation${count > 1 ? 's' : ''}';
    }
    return '$count résultat${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}';
  }

  // Check if any filters are active
  bool hasActiveFilters(String? searchQuery, String? statusFilter, String? categoryFilter) {
    return (searchQuery != null && searchQuery.isNotEmpty) ||
        (statusFilter != null && statusFilter != 'Tous') ||
        (categoryFilter != null && categoryFilter != 'Toutes');
  }

  // Get empty state message based on filters
  String getEmptyStateMessage(String? searchQuery, bool hasFilters) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return 'Aucun résultat pour "$searchQuery"';
    }
    if (hasFilters) {
      return 'Aucune réclamation ne correspond aux filtres';
    }
    return 'Aucune réclamation';
  }

  // Highlight search query in text (returns parts of text)
  List<Map<String, dynamic>> highlightSearchQuery(String text, String? query) {
    if (query == null || query.isEmpty) {
      return [{'text': text, 'highlight': false}];
    }

    final normalizedText = _normalizeString(text.toLowerCase());
    final normalizedQuery = _normalizeString(query.toLowerCase());

    if (!normalizedText.contains(normalizedQuery)) {
      return [{'text': text, 'highlight': false}];
    }

    List<Map<String, dynamic>> parts = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final normalizedSubstring = _normalizeString(
          text.substring(currentIndex).toLowerCase()
      );
      final matchIndex = normalizedSubstring.indexOf(normalizedQuery);

      if (matchIndex == -1) {
        parts.add({
          'text': text.substring(currentIndex),
          'highlight': false,
        });
        break;
      }

      // Add non-highlighted part before match
      if (matchIndex > 0) {
        parts.add({
          'text': text.substring(currentIndex, currentIndex + matchIndex),
          'highlight': false,
        });
      }

      // Add highlighted match
      parts.add({
        'text': text.substring(
          currentIndex + matchIndex,
          currentIndex + matchIndex + query.length,
        ),
        'highlight': true,
      });

      currentIndex += matchIndex + query.length;
    }

    return parts;
  }
}