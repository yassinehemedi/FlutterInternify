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

  // 🧠 Sentiment Analysis State
  Map<String, dynamic>? _currentAnalysis;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reclamation?.title ?? '');
    _descriptionController = TextEditingController(text: widget.reclamation?.description ?? '');
    if (widget.reclamation != null) {
      _selectedCategory = widget.reclamation!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🧠 Analyze button clicked
  Future<void> _analyzeDescription() async {
    final text = _descriptionController.text.trim();

    if (text.isEmpty || text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une description d\'au moins 10 caractères'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentAnalysis = null;
      _hasAnalyzed = false;
    });

    try {
      // Call LLM API
      final analysis = await SentimentAnalysisService.analyzeSentiment(text);

      setState(() {
        _currentAnalysis = analysis;
        _hasAnalyzed = true;
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Analyse terminée'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _hasAnalyzed = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur d\'analyse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🧠 Get sentiment icon
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

  // 🧠 Get sentiment color
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

  // 🧠 Get priority color
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

  // 🧠 Get priority icon
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.flag;
      default:
        return Icons.flag_outlined;
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
                        onChanged: (_) {
                          // Reset analysis when description changes
                          if (_hasAnalyzed) {
                            setState(() {
                              _hasAnalyzed = false;
                              _currentAnalysis = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 🧠 ANALYZE BUTTON
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeDescription,
                        icon: _isAnalyzing
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(
                          _isAnalyzing ? 'Analyse en cours...' : '🔍 Analyser la priorité',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🧠 ANALYSIS RESULT DISPLAY
                      if (_hasAnalyzed && _currentAnalysis != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getPriorityColor(_currentAnalysis!['priority']).withOpacity(0.15),
                                _getPriorityColor(_currentAnalysis!['priority']).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getPriorityColor(_currentAnalysis!['priority']).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Résultat de l\'analyse',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Priority
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(_currentAnalysis!['priority']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getPriorityIcon(_currentAnalysis!['priority']),
                                      color: _getPriorityColor(_currentAnalysis!['priority']),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Priorité',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _currentAnalysis!['priority'].toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getPriorityColor(_currentAnalysis!['priority']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Sentiment
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getSentimentColor(_currentAnalysis!['sentiment']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getSentimentIcon(_currentAnalysis!['sentiment']),
                                      color: _getSentimentColor(_currentAnalysis!['sentiment']),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sentiment',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _currentAnalysis!['sentiment'].toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getSentimentColor(_currentAnalysis!['sentiment']),
                                          ),
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
                            // 🧠 Check if analyzed
                            if (!_hasAnalyzed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Veuillez analyser la description avant de sauvegarder'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            // 🧠 Use analyzed data
                            final result = await _service.saveReclamation(
                              id: widget.reclamation?.id,
                              title: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                              category: _selectedCategory,
                              userId: widget.userId,
                              createdAt: widget.reclamation?.createdAt,
                              sentiment: _currentAnalysis!['sentiment'],
                              priority: _currentAnalysis!['priority'],
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