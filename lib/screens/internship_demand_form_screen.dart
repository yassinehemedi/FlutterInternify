// filepath: lib/screens/internship_demand_form_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/internship_demand.dart';
import '../services/internship_demand_service.dart';
import '../services/UserService.dart';
import 'package:flutter/scheduler.dart';

class InternshipDemandFormScreen extends StatefulWidget {
  final int userId;
  final InternshipDemand? demand;

  const InternshipDemandFormScreen({Key? key, required this.userId, this.demand}) : super(key: key);

  @override
  State<InternshipDemandFormScreen> createState() => _InternshipDemandFormScreenState();
}

class _InternshipDemandFormScreenState extends State<InternshipDemandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final InternshipDemandService _service = InternshipDemandService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _companyPrefController;
  List<String> _attachments = [];

  // Duration dropdown state
  String? _selectedDuration;
  final List<String> _durations = ['1 mois', '2 mois', '3 mois', '6 mois', '12 mois', 'Autre'];

  // Domain dropdown state
  String? _selectedDomain;
  final List<String> _domains = ['IT', 'Management', 'Marketing', 'Finance', 'Design', 'Autre'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Prevent enterprise users from accessing this form (create/edit)
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await UserService.instance.getUserById(widget.userId);
        if (user != null && user.role == 'enterprise') {
          // Inform and close
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Accès refusé'),
                content: const Text('Les comptes entreprise ne peuvent pas créer ou modifier des demandes.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              ),
            ).then((_) {
              if (mounted) Navigator.of(context).pop(false);
            });
          }
        }
      } catch (e) {
        // ignore errors and allow form to operate
      }
    });

    _titleController = TextEditingController(text: widget.demand?.title ?? '');
    _descriptionController = TextEditingController(text: widget.demand?.description ?? '');
    _selectedDuration = widget.demand?.duration ?? _durations[3];
    _companyPrefController = TextEditingController(text: widget.demand?.companyPreference ?? '');
    _attachments = widget.demand?.attachments ?? [];
    _selectedDomain = widget.demand?.domain ?? null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _companyPrefController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le titre est obligatoire';
    if (v.trim().length < 5) return 'Le titre doit contenir au moins 5 caractères';
    return null;
  }

  String? _validateDescription(String? v) {
    if (v == null || v.trim().isEmpty) return 'La description est obligatoire';
    if (v.trim().length < 10) return 'La description doit contenir au moins 10 caractères';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final demand = InternshipDemand(
      id: widget.demand?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      duration: _selectedDuration ?? '',
      companyPreference: _companyPrefController.text.trim().isEmpty ? null : _companyPrefController.text.trim(),
      domain: _selectedDomain,
      attachments: _attachments,
      status: widget.demand?.status ?? 'En cours',
      userId: widget.userId,
      createdAt: widget.demand?.createdAt ?? DateTime.now(),
    );

    if (demand.id == null) {
      await _service.insertInternshipDemand(demand);
    } else {
      await _service.updateInternshipDemand(demand);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistré avec succès')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickAndSaveFile() async {
    // Pick a file using file picker
    dynamic result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
    } catch (e) {
      // MissingPluginException or other platform error — inform user with guidance
      final msg = 'File picker plugin not available. Please fully stop the app and rebuild (flutter clean && flutter pub get && flutter run).';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      // Also log to console
      debugPrint('FilePicker error: $e');
      return;
    }

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the file from the result
        final file = result.files.first;

        // Get the temporary directory of the device
        final dir = await getApplicationDocumentsDirectory();

        // Create an 'attachments' directory if not exists
        final attachmentDir = Directory('${dir.path}/attachments');
        if (!await attachmentDir.exists()) {
          await attachmentDir.create(recursive: true);
        }

        // Build a unique filename to avoid collisions
        final baseName = file.name;
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$baseName';
        final filePath = '${attachmentDir.path}/$uniqueName';
        final savedFile = File(filePath);

        if (file.bytes != null) {
          await savedFile.writeAsBytes(file.bytes!);
        } else if (file.path != null) {
          // Fallback: copy from original path
          final source = File(file.path!);
          if (await source.exists()) {
            await source.copy(savedFile.path);
          } else {
            throw Exception('Source file missing');
          }
        } else {
          throw Exception('No file data available');
        }

        // Add the file path to the attachments list
        setState(() {
          _attachments.add(savedFile.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier ajouté avec succès')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout du fichier')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.demand != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la demande' : 'Nouvelle demande de stage'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(isEditing ? 'Modifier les informations' : 'Remplissez le formulaire',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titre *',
                          prefixIcon: Icon(Icons.title, color: Colors.blue[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                        validator: _validateTitle,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          prefixIcon: Icon(Icons.description, color: Colors.blue[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
                          filled: true,
                          fillColor: Colors.blue[50],
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        maxLength: 500,
                        validator: _validateDescription,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Duration dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDuration,
                        decoration: InputDecoration(
                          labelText: 'Durée *',
                          prefixIcon: Icon(Icons.timelapse, color: Colors.blue[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                        items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _selectedDuration = v),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'La durée est obligatoire' : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _companyPrefController,
                        decoration: InputDecoration(
                          labelText: 'Préférence entreprise (optionnel)',
                          prefixIcon: Icon(Icons.business, color: Colors.blue[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Domain dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDomain,
                        decoration: InputDecoration(
                          labelText: 'Domaine (optionnel)',
                          prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
                          filled: true,
                          fillColor: Colors.blue[50],
                        ),
                        items: _domains.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _selectedDomain = v),
                      ),

                      const SizedBox(height: 16),

                      // Attachments: pick a file (CV) and store it locally
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Ajouter un fichier (CV)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            onPressed: _pickAndSaveFile,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 8),
                      if (_attachments.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fichiers joints', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._attachments.map((a) => ListTile(
                                  leading: const Icon(Icons.insert_drive_file, size: 28, color: Colors.blue),
                                  title: Text(p.basename(a), style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(a, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: const Icon(Icons.open_in_new), onPressed: () async { await OpenFile.open(a); }),
                                    IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                                      // delete the copied file from storage and remove from list
                                      try {
                                        final f = File(a);
                                        if (await f.exists()) await f.delete();
                                      } catch (e) {}
                                      setState(() {
                                        _attachments.remove(a);
                                      });
                                    }),
                                  ]),
                                )),
                            const SizedBox(height: 8),
                          ],
                        ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isEditing ? Icons.save : Icons.add_circle), const SizedBox(width: 8), Text(isEditing ? 'Enregistrer' : 'Ajouter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.blue[700]!)),
                        child: const Text('Annuler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
