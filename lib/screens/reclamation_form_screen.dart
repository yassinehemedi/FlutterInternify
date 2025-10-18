import 'package:flutter/material.dart';
import '../models/reclamation.dart';
import '../services/SentimentAnalysisService.dart';
import '../services/reclamation_service.dart';

class ReclamationFormScreen extends StatefulWidget {
  final int userId;
  final Reclamation? reclamation;

  const ReclamationFormScreen({
    Key? key,
    required this.userId,
    this.reclamation,
  }) : super(key: key);

  @override
  State<ReclamationFormScreen> createState() => _ReclamationFormScreenState();
}

class _ReclamationFormScreenState extends State<ReclamationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReclamationService _service = ReclamationService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Technique';
  bool _isLoading = false;

  // 🧠 NEW: Sentiment Analysis State
  Map<String, dynamic>? _currentAnalysis;
  bool _showAnalysisPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reclamation?.title ?? '');
    _descriptionController = TextEditingController(text: widget.reclamation?.description ?? '');
    if (widget.reclamation != null) {
      _selectedCategory = widget.reclamation!.category;
      // 🧠 NEW: Analyze existing description
      if (widget.reclamation!.description.isNotEmpty) {
        _analyzeDescription(widget.reclamation!.description);
      }
    }
    // 🧠 NEW: Listen to description changes
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged); // 🧠 NEW
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🧠 NEW: Auto-analyze when description changes
  void _onDescriptionChanged() {
    final text = _descriptionController.text.trim();
    if (text.length > 10) {
      _analyzeDescription(text);
    } else {
      setState(() {
        _currentAnalysis = null;
        _showAnalysisPreview = false;
      });
    }
  }

  // 🧠 NEW: Perform sentiment analysis
  void _analyzeDescription(String text) {
    final analysis = SentimentAnalysisService.analyzeSentiment(text);
    setState(() {
      _currentAnalysis = analysis;
      _showAnalysisPreview = true;
    });
  }

  // 🧠 NEW: Get sentiment icon
  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_satisfied_alt;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // 🧠 NEW: Get sentiment color
  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // 🧠 NEW: Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reclamation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la réclamation' : 'Nouvelle réclamation'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.white],
            stops: const [0.0, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? 'Modifier les informations' : 'Remplissez le formulaire',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titre *',
                          hintText: 'Ex: Problème de connexion',
                          prefixIcon: Icon(Icons.title, color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                        validator: _service.validateTitle,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Décrivez votre réclamation en détail...',
                          prefixIcon: Icon(Icons.description, color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue[50],
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        maxLength: 500,
                        validator: _service.validateDescription,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 8),

                      // 🧠 NEW: SENTIMENT ANALYSIS PREVIEW
                      if (_showAnalysisPreview && _currentAnalysis != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getSentimentColor(_currentAnalysis!['sentiment']).withOpacity(0.1),
                                _getSentimentColor(_currentAnalysis!['sentiment']).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getSentimentColor(_currentAnalysis!['sentiment']).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Colors.purple[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Analyse automatique',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Sentiment
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getSentimentIcon(_currentAnalysis!['sentiment']),
                                          size: 20,
                                          color: _getSentimentColor(_currentAnalysis!['sentiment']),
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sentiment',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _currentAnalysis!['sentiment'].toString().toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getSentimentColor(_currentAnalysis!['sentiment']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Priority
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 20,
                                          color: _getPriorityColor(_currentAnalysis!['priority']),
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Priorité',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _currentAnalysis!['priority'].toString().toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getPriorityColor(_currentAnalysis!['priority']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Catégorie *',
                          prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                        items: _service.getCategories().map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                        validator: _service.validateCategory,
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Statut : En cours (non modifiable)',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '* Champs obligatoires',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);

                            // 🧠 NEW: Analyze before saving
                            final description = _descriptionController.text.trim();
                            final analysis = SentimentAnalysisService.analyzeSentiment(description);

                            // 🧠 NEW: Call saveReclamation with sentiment data
                            final result = await _service.saveReclamation(
                              id: widget.reclamation?.id,
                              title: _titleController.text.trim(),
                              description: description,
                              category: _selectedCategory,
                              userId: widget.userId,
                              createdAt: widget.reclamation?.createdAt,
                              sentiment: analysis['sentiment'],     // 🧠 NEW
                              priority: analysis['priority'],       // 🧠 NEW
                            );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message']),
                                  backgroundColor: result['success']
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                              if (result['success']) {
                                Navigator.pop(context, true);
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEditing ? Icons.save : Icons.add_circle),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Enregistrer' : 'Ajouter',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue[700]!),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}