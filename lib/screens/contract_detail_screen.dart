import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';
import '../theme/app_theme.dart';
import 'signature_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContractDetailScreen extends StatefulWidget {
  final Contract contract;

  const ContractDetailScreen({
    super.key,
    required this.contract,
  });

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContractService _contractService = ContractService.instance;

  late TextEditingController _titleController;
  late TextEditingController _jobSeekerIdController;
  late TextEditingController _enterpriseIdController;
  late TextEditingController _descriptionController;

  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  String? _contractType;
  bool _isEditing = false;
  bool _isLoading = false;
  late Contract _currentContract;

  final List<String> _statusOptions = [
    'Pending',
    'Signed',
    'Active',
    'Expired',
  ];

  final List<String> _contractTypes = [
    'Internship Agreement',
    'NDA',
    'Full-time Contract',
    'Part-time Contract',
    'Freelance Agreement',
  ];

  @override
  void initState() {
    super.initState();
    _currentContract = widget.contract;
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _currentContract.title ?? '');
    _jobSeekerIdController = TextEditingController(
      text: _currentContract.jobSeekerId.toString(),
    );
    _enterpriseIdController = TextEditingController(
      text: _currentContract.enterpriseId.toString(),
    );
    _descriptionController = TextEditingController(
      text: _currentContract.description ?? '',
    );
    _startDate = DateTime.parse(_currentContract.startDate);
    _endDate = DateTime.parse(_currentContract.endDate);
    _status = _currentContract.status;
    _contractType = _currentContract.contractType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _jobSeekerIdController.dispose();
    _enterpriseIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _signContract() async {
    // Navigate to signature screen
    final signaturePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureScreen(contractId: _currentContract.id!),
      ),
    );

    if (signaturePath != null) {
      setState(() => _isLoading = true);

      try {
        // Save signature and update status
        await _contractService.signContract(_currentContract.id!, signaturePath);

        // Reload contract data
        final updatedContract = await _contractService.getContractById(_currentContract.id!);

        setState(() {
          _isLoading = false;
          if (updatedContract != null) {
            _currentContract = updatedContract;
            _status = updatedContract.status;
          }
        });

        _showSuccessSnackBar('Contract signed successfully!');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to sign contract: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _updateContract() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showErrorSnackBar('End date cannot be before start date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedContract = _currentContract.copyWith(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        jobSeekerId: int.parse(_jobSeekerIdController.text.trim()),
        enterpriseId: int.parse(_enterpriseIdController.text.trim()),
        startDate: _startDate.toIso8601String().split('T')[0],
        endDate: _endDate.toIso8601String().split('T')[0],
        status: _status,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim().substring(0,
            _descriptionController.text.trim().length > 20
                ? 20
                : _descriptionController.text.trim().length),
        contractType: _contractType,
      );

      await _contractService.updateContract(updatedContract);

      setState(() {
        _isLoading = false;
        _isEditing = false;
        _currentContract = updatedContract;
      });
      _showSuccessSnackBar('Contract updated successfully');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to update contract: $e');
    }
  }

  Future<void> _downloadContract() async {
    try {
      setState(() => _isLoading = true);
      final path = await _contractService.downloadContract(_currentContract.id!);
      setState(() => _isLoading = false);
      _showSuccessSnackBar('Contract downloaded to: $path');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to download contract: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        title: Text(
          _isEditing ? 'Edit Contract' : 'Contract Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing && _currentContract.status != 'Signed')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadContract,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing ? _buildEditForm() : _buildViewMode(),
      ),
      bottomNavigationBar: _isEditing
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initializeControllers();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _updateContract,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : (_currentContract.status == 'Pending'
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _signContract,
          icon: const Icon(Icons.draw, color: Colors.white),
          label: const Text(
            'Sign Contract',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      )
          : null),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentContract.title ?? 'Untitled Contract',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _status == 'Signed'
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentContract.signaturePath != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Digitally Signed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard('Contract Information', [
          _buildInfoRow('Contract Type', _contractType ?? 'Not specified',
              Icons.description),
          _buildInfoRow('Job Seeker ID', _currentContract.jobSeekerId.toString(),
              Icons.person),
          _buildInfoRow('Enterprise ID', _currentContract.enterpriseId.toString(),
              Icons.business),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Duration', [
          _buildInfoRow('Start Date',
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              Icons.play_arrow),
          _buildInfoRow('End Date',
              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
              Icons.stop),
        ]),
        if (_currentContract.description != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Description', [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _currentContract.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                ),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Contract Title',
            icon: Icons.title,
            required: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _jobSeekerIdController,
            label: 'Job Seeker ID',
            icon: Icons.person,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _enterpriseIdController,
            label: 'Enterprise ID',
            icon: Icons.business,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Contract Type',
            value: _contractType,
            items: _contractTypes,
            onChanged: (value) {
              setState(() {
                _contractType = value;
              });
            },
            icon: Icons.description,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Status',
            value: _status,
            items: _statusOptions,
            onChanged: (value) {
              setState(() {
                _status = value!;
              });
            },
            icon: Icons.flag,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (max 20 chars)',
            icon: Icons.notes,
            maxLength: 20,
            required: false,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}