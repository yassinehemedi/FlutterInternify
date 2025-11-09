import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../theme/app_theme.dart';

class ApplicationFormScreen extends StatefulWidget {
  final int userId;
  final int offerId;
  final ApplicationModel? application;
  const ApplicationFormScreen(
      {super.key,
      required this.userId,
      required this.offerId,
      this.application});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String? _cvPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.application != null) {
      _messageController.text = widget.application!.motivationalMessage ?? '';
      _cvPath = widget.application!.cvFile;
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCv() async {
    // Fallback: allow image selection as CV (for demo). For full file support, add file_picker plugin.
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
    await file.writeAsBytes(bytes);
    setState(() => _cvPath = file.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Ensure CV is present for new applications
    if (widget.application == null && (_cvPath == null || _cvPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload your CV before submitting')));
      return;
    }
    setState(() => _isSubmitting = true);

    if (widget.application == null) {
      final app = ApplicationModel(
        cvFile: _cvPath,
        motivationalMessage: _messageController.text.trim(),
        userId: widget.userId,
        offerId: widget.offerId,
      );
      final created = await ApplicationService.instance.createApplication(app);
      setState(() => _isSubmitting = false);
      Navigator.pop(context, created);
    } else {
      final updated = widget.application!.copyWith(
          cvFile: _cvPath, motivationalMessage: _messageController.text.trim());
      await ApplicationService.instance.updateApplication(updated);
      setState(() => _isSubmitting = false);
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Apply'), backgroundColor: AppTheme.primaryBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_cvPath != null)
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(_cvPath!.split('/').last),
                trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _cvPath = null)),
              ),
            ElevatedButton.icon(
              onPressed: _pickCv,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CV (pdf/doc)'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                        labelText: 'Motivational message'),
                    maxLines: 6,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a message'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
