import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';
import '../theme/app_theme.dart';

class OfferFormScreen extends StatefulWidget {
  final int userId;
  final Offer? offer; // null means create

  const OfferFormScreen({super.key, required this.userId, this.offer});

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _imagePath;
  DateTime? _expiresAt;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.offer != null) {
      _titleController.text = widget.offer!.title;
      _descriptionController.text = widget.offer!.description ?? '';
      _categoryController.text = widget.offer!.category ?? '';
      _imagePath = widget.offer!.image;
      _expiresAt = widget.offer!.expiresAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
    await file.writeAsBytes(bytes);
    setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final offer = Offer(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      image: _imagePath,
      expiresAt: _expiresAt,
      userId: widget.userId,
    );

    if (widget.offer == null) {
      final created = await OfferService.instance.createOffer(offer);
      setState(() => _isSaving = false);
      Navigator.pop(context, created);
    } else {
      final updated = offer.copyWith(idOffer: widget.offer!.idOffer);
      await OfferService.instance.updateOffer(updated);
      setState(() => _isSaving = false);
      Navigator.pop(context, updated);
    }
  }

  Widget _buildImagePreview() {
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_imagePath!),
            width: double.infinity, height: 180, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 64, color: AppTheme.primaryBlue.withOpacity(0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer == null ? 'Create Offer' : 'Edit Offer'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose Image'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                if (_imagePath != null)
                  TextButton(
                    onPressed: () => setState(() => _imagePath = null),
                    child: const Text('Remove'),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_expiresAt == null
                            ? 'No expiry date'
                            : 'Expires: ${_expiresAt!.toLocal().toString().split(' ')[0]}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _expiresAt ?? now.add(const Duration(days: 30)),
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null)
                            setState(() => _expiresAt = picked);
                        },
                        child: const Text('Set expiry'),
                      ),
                      if (_expiresAt != null)
                        TextButton(
                            onPressed: () => setState(() => _expiresAt = null),
                            child: const Text('Clear'))
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a category'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 5,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.offer == null
                              ? 'Create Offer'
                              : 'Save Changes'),
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
