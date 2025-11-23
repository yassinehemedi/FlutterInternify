import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import 'add_contract_screen.dart';
import 'contract_detail_screen.dart';
import 'contract_stats_screen.dart';

class ContractsListScreen extends StatefulWidget {
  const ContractsListScreen({super.key});

  @override
  State<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends State<ContractsListScreen> {
  final ContractService _contractService = ContractService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Contract> _contracts = [];
  List<Contract> _filteredContracts = [];
  bool _isLoading = true;
  String _filterStatus = 'All';
  String _filterContractType = 'All';

  // ✅ User filtering variables
  String? _userRole;
  int? _currentUserId;
  int? _currentJobSeekerId;
  int? _currentEnterpriseId;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndContracts();
    _searchController.addListener(_filterContracts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ NEW: Load user data first, then filter contracts
  Future<void> _loadUserDataAndContracts() async {
    setState(() => _isLoading = true);
    try {
      // Get current user info
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('userId');
      _userRole = prefs.getString('userRole');

      print('🔍 Logged in - UserID: $_currentUserId, Role: $_userRole');

      if (_currentUserId == null || _userRole == null) {
        _showErrorSnackBar('User not logged in');
        return;
      }

      final db = await DatabaseHelper.instance.database;

      // Get role-specific ID
      if (_userRole == 'enterprise') {
        final enterpriseResult = await db.query(
          'enterprises',
          where: 'userId = ?',
          whereArgs: [_currentUserId],
        );
        if (enterpriseResult.isNotEmpty) {
          _currentEnterpriseId = enterpriseResult.first['id'] as int;
          print('✅ Enterprise ID: $_currentEnterpriseId');
        }
      } else if (_userRole == 'job_seeker') {
        final jobSeekerResult = await db.query(
          'job_seekers',
          where: 'userId = ?',
          whereArgs: [_currentUserId],
        );
        if (jobSeekerResult.isNotEmpty) {
          _currentJobSeekerId = jobSeekerResult.first['id'] as int;
          print('✅ Job Seeker ID: $_currentJobSeekerId');
        }
      }

      // Now load contracts
      await _loadContracts();

    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading user data: $e');
      _showErrorSnackBar('Failed to load user data: $e');
    }
  }

  // ✅ UPDATED: Filter contracts by current user
  Future<void> _loadContracts() async {
    try {
      List<Contract> contracts;

      // Filter based on user role
      if (_userRole == 'enterprise' && _currentEnterpriseId != null) {
        contracts = await _contractService.getContractsByEnterprise(_currentEnterpriseId!);
        print('📄 Loaded ${contracts.length} contracts for enterprise $_currentEnterpriseId');
      } else if (_userRole == 'job_seeker' && _currentJobSeekerId != null) {
        contracts = await _contractService.getContractsByJobSeeker(_currentJobSeekerId!);
        print('📄 Loaded ${contracts.length} contracts for job seeker $_currentJobSeekerId');
      } else {
        contracts = [];
        print('⚠️ No role-specific ID found, showing no contracts');
      }

      setState(() {
        _contracts = contracts;
        _filterContracts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading contracts: $e');
      _showErrorSnackBar('Failed to load contracts: $e');
    }
  }

  void _filterContracts() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredContracts = _contracts.where((contract) {
        // Filter by status
        bool matchesStatus = _filterStatus == 'All' || contract.status == _filterStatus;

        // Filter by contract type
        bool matchesType = _filterContractType == 'All' ||
            (contract.contractType != null && contract.contractType == _filterContractType);

        // Search filter
        bool matchesSearch = query.isEmpty ||
            (contract.title?.toLowerCase().contains(query) ?? false) ||
            contract.id.toString().contains(query) ||
            contract.jobSeekerId.toString().contains(query) ||
            contract.enterpriseId.toString().contains(query) ||
            contract.status.toLowerCase().contains(query) ||
            (contract.contractType?.toLowerCase().contains(query) ?? false) ||
            (contract.description?.toLowerCase().contains(query) ?? false) ||
            contract.startDate.contains(query) ||
            contract.endDate.contains(query);

        return matchesStatus && matchesType && matchesSearch;
      }).toList();
    });
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

  Future<void> _deleteContract(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contract'),
        content: const Text('Are you sure you want to delete this contract?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _contractService.deleteContract(id);
        _showSuccessSnackBar('Contract deleted successfully');
        _loadContracts();
      } catch (e) {
        _showErrorSnackBar('Failed to delete contract: $e');
      }
    }
  }

  Future<void> _downloadContract(int id) async {
    try {
      final path = await _contractService.downloadContract(id);

      // Show dialog with download location
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Download Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your contract has been downloaded successfully!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  path,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can find it in your Downloads folder or File Manager.',
                style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to download contract: $e');
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Contracts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            if (_userRole != null)
              Text(
                _userRole == 'enterprise' ? 'Enterprise View' : 'Job Seeker View',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContractStatsScreen(contracts: _contracts),
                ),
              );
            },
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, ID, dates, status...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Active Filters Display
          if (_filterStatus != 'All' || _filterContractType != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterStatus != 'All')
                    Chip(
                      label: Text('Status: $_filterStatus'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filterStatus = 'All';
                          _filterContracts();
                        });
                      },
                    ),
                  if (_filterContractType != 'All')
                    Chip(
                      label: Text('Type: $_filterContractType'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filterContractType = 'All';
                          _filterContracts();
                        });
                      },
                    ),
                ],
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredContracts.length} contract${_filteredContracts.length != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Contracts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContracts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadContracts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredContracts.length,
                itemBuilder: (context, index) {
                  final contract = _filteredContracts[index];
                  return _buildContractCard(contract);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContractScreen(),
            ),
          );
          if (result == true) {
            _loadContracts();
          }
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Contract'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _filterStatus != 'All' || _filterContractType != 'All'
                ? 'No contracts match your search'
                : 'No contracts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _filterStatus != 'All' || _filterContractType != 'All'
                ? 'Try adjusting your filters'
                : 'Tap the + button to create one',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Contract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailScreen(contract: contract),
            ),
          );
          if (result == true) {
            _loadContracts();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contract.title ?? 'Untitled Contract',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(contract.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(contract.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      contract.status,
                      style: TextStyle(
                        color: _getStatusColor(contract.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (contract.contractType != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      contract.contractType!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${contract.startDate} → ${contract.endDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.badge,
                    size: 16,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Job Seeker ID: ${contract.jobSeekerId} | Enterprise ID: ${contract.enterpriseId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
              if (contract.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  contract.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.accentBlue),
                    onPressed: () => _downloadContract(contract.id!),
                    tooltip: 'Download',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContract(contract.id!),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Contracts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildFilterOption('All', true),
              _buildFilterOption('Pending', true),
              _buildFilterOption('Signed', true),
              _buildFilterOption('Active', true),
              _buildFilterOption('Expired', true),
              const SizedBox(height: 16),
              const Text(
                'Contract Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildFilterOption('All', false),
              _buildFilterOption('Internship Agreement', false),
              _buildFilterOption('NDA', false),
              _buildFilterOption('Full-time Contract', false),
              _buildFilterOption('Part-time Contract', false),
              _buildFilterOption('Freelance Agreement', false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'All';
                _filterContractType = 'All';
                _filterContracts();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String value, bool isStatus) {
    final isSelected = isStatus
        ? _filterStatus == value
        : _filterContractType == value;

    return RadioListTile<String>(
      title: Text(value),
      value: value,
      groupValue: isStatus ? _filterStatus : _filterContractType,
      onChanged: (newValue) {
        setState(() {
          if (isStatus) {
            _filterStatus = newValue!;
          } else {
            _filterContractType = newValue!;
          }
          _filterContracts();
        });
        Navigator.pop(context);
      },
      dense: true,
    );
  }
}