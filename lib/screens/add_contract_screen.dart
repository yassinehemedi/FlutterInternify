import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contract_model.dart';
import '../models/jobseeker_model.dart';
import '../models/entreprise_model.dart';
import '../services/contract_service.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class AddContractScreen extends StatefulWidget {
  const AddContractScreen({super.key});

  @override
  State<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends State<AddContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContractService _contractService = ContractService.instance;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'Pending';
  String? _contractType;
  bool _isLoading = false;

  // PDF file
  File? _pdfFile;
  String? _pdfFileName;

  // User role and IDs
  String? _userRole;
  int? _currentUserId;
  int? _currentJobSeekerId;
  int? _currentEnterpriseId;

  // Dropdowns for relationships
  List<JobSeeker> _jobSeekers = [];
  List<Enterprise> _enterprises = [];
  int? _selectedJobSeekerId;
  int? _selectedEnterpriseId;

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
    _loadUserRoleAndData();
  }

  Future<void> _loadUserRoleAndData() async {
    setState(() => _isLoading = true);
    try {
      // Get current user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('userId');
      _userRole = prefs.getString('userRole');

      print('🔍 Loading data - UserID: $_currentUserId, Role: $_userRole'); // Debug

      if (_currentUserId == null || _userRole == null) {
        _showErrorSnackBar('User not logged in');
        Navigator.pop(context);
        return;
      }

      final db = await DatabaseHelper.instance.database;

      // Load based on user role
      if (_userRole == 'enterprise') {
        // Load current enterprise's ID
        final enterpriseResult = await db.query(
          'enterprises',
          where: 'userId = ?',
          whereArgs: [_currentUserId],
        );

        print('📊 Enterprise query result: $enterpriseResult'); // Debug

        if (enterpriseResult.isNotEmpty) {
          _currentEnterpriseId = enterpriseResult.first['id'] as int;
          _selectedEnterpriseId = _currentEnterpriseId;
        }

        // Load all job seekers
        final jobSeekersResult = await db.query('job_seekers');
        _jobSeekers = jobSeekersResult.map((map) => JobSeeker.fromMap(map)).toList();
        print('✅ Loaded ${_jobSeekers.length} job seekers'); // Debug

      } else if (_userRole == 'job_seeker') {
        // Load current job seeker's ID
        final jobSeekerResult = await db.query(
          'job_seekers',
          where: 'userId = ?',
          whereArgs: [_currentUserId],
        );

        print('📊 Job seeker query result: $jobSeekerResult'); // Debug

        if (jobSeekerResult.isNotEmpty) {
          _currentJobSeekerId = jobSeekerResult.first['id'] as int;
          _selectedJobSeekerId = _currentJobSeekerId;
        }

        // ✅ FIX: Load all enterprises properly
        final enterprisesResult = await db.query('enterprises');
        print('📊 Enterprises raw query: $enterprisesResult'); // Debug

        _enterprises = enterprisesResult.map((map) => Enterprise.fromMap(map)).toList();
        print('✅ Loaded ${_enterprises.length} enterprises for dropdown'); // Debug

        // Print each enterprise for debugging
        for (var enterprise in _enterprises) {
          print('Enterprise - ID: ${enterprise.id}, UserID: ${enterprise.userId}, Name: ${enterprise.companyName}');
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading data: $e'); // Debug
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _pdfFile = File(result.files.single.path!);
          _pdfFileName = result.files.single.name;
        });
        _showSuccessSnackBar('PDF file selected: $_pdfFileName');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking PDF file: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  Future<void> _saveContract() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedJobSeekerId == null) {
      _showErrorSnackBar('Please select a job seeker');
      return;
    }

    if (_selectedEnterpriseId == null) {
      _showErrorSnackBar('Please select an enterprise');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showErrorSnackBar('Please select both start and end dates');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showErrorSnackBar('End date cannot be before start date');
      return;
    }

    if (_pdfFile == null) {
      _showErrorSnackBar('Please upload a PDF contract file');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final contract = Contract(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        jobSeekerId: _selectedJobSeekerId!,
        enterpriseId: _selectedEnterpriseId!,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
        status: _status,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim().substring(0,
            _descriptionController.text.trim().length > 20
                ? 20
                : _descriptionController.text.trim().length),
        contractType: _contractType,
        pdfPath: _pdfFile!.path,
      );

      await _contractService.createContract(contract);

      setState(() => _isLoading = false);
      _showSuccessSnackBar('Contract created successfully with watermark');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to create contract: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          'New Contract',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Upload Contract PDF'),
              const SizedBox(height: 16),
              _buildPdfUploadCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Contract Title',
                hint: 'e.g., Software Developer Internship',
                icon: Icons.title,
                required: false,
              ),
              const SizedBox(height: 16),

              // Show dropdowns based on user role
              if (_userRole == 'enterprise') ...[
                _buildJobSeekerDropdown(),
                const SizedBox(height: 16),
                _buildFixedEnterpriseInfo(),
              ] else if (_userRole == 'job_seeker') ...[
                _buildFixedJobSeekerInfo(),
                const SizedBox(height: 16),
                _buildEnterpriseDropdown(),
              ],

              const SizedBox(height: 24),
              _buildSectionTitle('Contract Details'),
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
                hint: 'Brief description',
                icon: Icons.notes,
                maxLength: 20,
                required: false,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Duration'),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveContract,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Contract with Watermark',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedJobSeekerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Seeker (You)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $_currentJobSeekerId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: AppTheme.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildFixedEnterpriseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enterprise (You)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $_currentEnterpriseId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: AppTheme.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildJobSeekerDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedJobSeekerId,
      decoration: InputDecoration(
        labelText: 'Select Job Seeker',
        prefixIcon: const Icon(Icons.person, color: AppTheme.primaryBlue),
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
      hint: const Text('Select Job Seeker'),
      items: _jobSeekers.map((jobSeeker) {
        return DropdownMenuItem(
          value: jobSeeker.id,
          child: Text('ID: ${jobSeeker.id} - User ID: ${jobSeeker.userId}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedJobSeekerId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a job seeker';
        }
        return null;
      },
    );
  }

  Widget _buildEnterpriseDropdown() {
    // ✅ FIX: Add debug info and better display
    print('🔄 Building enterprise dropdown with ${_enterprises.length} enterprises');

    return DropdownButtonFormField<int>(
      value: _selectedEnterpriseId,
      decoration: InputDecoration(
        labelText: 'Select Enterprise',
        prefixIcon: const Icon(Icons.business, color: AppTheme.primaryBlue),
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
      hint: const Text('Select Enterprise'),
      items: _enterprises.isEmpty
          ? [
        const DropdownMenuItem(
          value: null,
          enabled: false,
          child: Text('No enterprises available', style: TextStyle(color: Colors.grey)),
        )
      ]
          : _enterprises.map((enterprise) {
        return DropdownMenuItem(
          value: enterprise.id,
          child: Text(
            enterprise.companyName != null && enterprise.companyName!.isNotEmpty
                ? '${enterprise.companyName} (ID: ${enterprise.id})'
                : 'Enterprise ID: ${enterprise.id} - User ID: ${enterprise.userId}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _enterprises.isEmpty ? null : (value) {
        setState(() {
          _selectedEnterpriseId = value;
        });
        print('✅ Selected enterprise ID: $value');
      },
      validator: (value) {
        if (value == null && _enterprises.isNotEmpty) {
          return 'Please select an enterprise';
        }
        return null;
      },
    );
  }

  Widget _buildPdfUploadCard() {
    return InkWell(
      onTap: _pickPdfFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pdfFile != null ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _pdfFile != null ? Icons.check_circle : Icons.upload_file,
              size: 48,
              color: _pdfFile != null ? Colors.green : AppTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
            Text(
              _pdfFile != null ? 'PDF Selected' : 'Upload Contract PDF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _pdfFile != null ? Colors.green : AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _pdfFile != null
                  ? _pdfFileName!
                  : 'Tap to select PDF file',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_pdfFile != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _pdfFile = null;
                    _pdfFileName = null;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      validator: validator ??
              (value) {
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
    required DateTime? date,
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
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? Colors.black : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}