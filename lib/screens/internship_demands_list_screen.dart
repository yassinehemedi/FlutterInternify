// filepath: lib/screens/internship_demands_list_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import '../services/cv_parser_service.dart';
import '../models/internship_demand.dart';
import '../services/internship_demand_service.dart';
import '../services/reclamation_service.dart';
import '../services/statistics_service.dart';
import '../services/search_service.dart';
import '../services/UserService.dart';
import 'internship_demand_statistics_screen.dart';
import 'package:internify/screens/internship_demand_form_screen.dart' as demand_form;

class InternshipDemandsListScreen extends StatefulWidget {
  final int userId;
  const InternshipDemandsListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<InternshipDemandsListScreen> createState() => _InternshipDemandsListScreenState();
}

class _InternshipDemandsListScreenState extends State<InternshipDemandsListScreen> {
  final InternshipDemandService _service = InternshipDemandService();
  final UserService _userService = UserService.instance;
  final ReclamationService _reclamationService = ReclamationService(); // for utility methods like formatDate/getStatusColorName
  final StatisticsService _statsService = StatisticsService();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  List<InternshipDemand> _items = [];
  List<InternshipDemand> _filtered = [];
  bool _isLoading = true;
  String? _selectedStatus;

  // Domain filter dropdown
  final List<String> _domains = ['IT', 'Management', 'Marketing', 'Finance', 'Design', 'Autre'];
  String _selectedDomainFilter = 'Tous';

  List<String> _availableStatuses = ['Tous'];
  bool _isEnterprise = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'Tous';
    _initRoleAndLoad();
  }

  Future<void> _initRoleAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final enterprise = await _userService.getEnterpriseByUserId(
          widget.userId);
      if (enterprise != null) {
        _isEnterprise = true;
      } else {
        _isEnterprise = false;
      }
    } catch (e) {
      _isEnterprise = false;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    List<InternshipDemand> data = [];
    if (_isEnterprise) {
      // Enterprise users can view all demands (read-only)
      data = await _service.getAllDemands();
    } else {
      data = await _service.getByUserId(widget.userId);
    }
    setState(() {
      _items = data;
      final statuses = _items.map((d) => d.status).toSet().toList()
        ..sort();
      _availableStatuses = ['Tous', ...statuses];
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _items.where((d) {
        if (_selectedStatus != null && _selectedStatus != 'Tous' &&
            d.status != _selectedStatus) return false;
        if (_selectedDomainFilter != 'Tous' && (d.domain ?? '') != _selectedDomainFilter) return false;
        if (query.isEmpty) return true;
        final inTitle = d.title.toLowerCase().contains(query);
        final inDesc = d.description.toLowerCase().contains(query);
        final inDuration = d.duration.toLowerCase().contains(query);
        final inDomain = (d.domain ?? '').toLowerCase().contains(query);
        return inTitle || inDesc || inDuration || inDomain;
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Demandes de Stage'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'pdf') await _exportPdf();
              if (v == 'csv') await _exportCsv();
            },
            itemBuilder: (context) =>
            [
              const PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
              const PopupMenuItem(value: 'csv', child: Text('Exporter CSV')),
            ],
            icon: const Icon(Icons.share),
          ),
        ],
        backgroundColor: Colors.blue[700],
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
            ? const Center(
            child: CircularProgressIndicator(color: Colors.white))
            : _items.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.blue[300]),
              const SizedBox(height: 16),
              Text(
                'Aucune demande de stage',
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
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) =>
                        InternshipDemandStatisticsScreen(demands: _items)));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [
                      Colors.blue[600]!,
                      Colors.blue[800]!
                    ]), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.analytics_outlined, color: Colors.white,
                              size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statsService.getSummaryText({
                                  'byStatus': _buildStatusCount(),
                                  'total': _items.length
                                }),
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Total: ${_items.length} demandes',
                                  style: TextStyle(
                                      color: Colors.white.withAlpha(
                                          (0.9 * 255).round()), fontSize: 13)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white
                            .withAlpha((0.8 * 255).round()), size: 18),
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
                onChanged: (v) => _applyFilters(),
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
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.blue[700]!, width: 2)),
                ),
              ),
            ),

            // Domain filter dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<String>(
                value: _selectedDomainFilter,
                decoration: InputDecoration(
                  labelText: 'Domaine',
                  prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: ['Tous', ..._domains].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {
                  _selectedDomainFilter = v ?? 'Tous';
                  _applyFilters();
                },
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
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = status;
                            _applyFilters();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[700],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue[900] : Colors
                              .grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight
                              .normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.blue[700]! : Colors
                              .grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchService.getEmptyStateMessage(
                          _searchController.text.isNotEmpty ? _searchController
                              .text : null, _searchService.hasActiveFilters(
                          _searchController.text, _selectedStatus, null)),
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    if (_searchService.hasActiveFilters(
                        _searchController.text, _selectedStatus, null)) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _selectedStatus = 'Tous';
                          });
                          _applyFilters();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réinitialiser les filtres'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors
                            .blue[700], foregroundColor: Colors.white),
                      ),
                    ],
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final d = _filtered[index];
                  final statusColor = _getColorFromName(
                      _reclamationService.getStatusColorName(d.status));
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16, top: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () async {
                        if (_isEnterprise) {
                          // For enterprises, show detail & respond dialog
                          _showEnterpriseDetailDialog(d);
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                demand_form.InternshipDemandFormScreen(
                                    userId: widget.userId, demand: d)),
                          );
                          if (result == true) _loadData();
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
                                    d.title,
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900]),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(
                                        (0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: statusColor, width: 1.5),
                                  ),
                                  child: Text(d.status, style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(d.description, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Icon(Icons.timelapse, size: 16,
                                  color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              Text(d.duration, style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Icon(Icons.access_time, size: 16,
                                  color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(_reclamationService.formatDate(d.createdAt),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ]),
                            const SizedBox(height: 12),
                            if (d.domain != null && d.domain!.isNotEmpty) ...[
                              Row(children: [
                                Icon(Icons.category, size: 16, color: Colors.deepPurple),
                                const SizedBox(width: 6),
                                Text(d.domain!, style: TextStyle(color: Colors.deepPurple, fontSize: 13, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 12),
                            ],
                            Row(mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!_isEnterprise) ...[
                                    TextButton.icon(onPressed: () async {
                                      final result = await Navigator.push(
                                        context, MaterialPageRoute(
                                          builder: (context) =>
                                              demand_form
                                                  .InternshipDemandFormScreen(
                                                  userId: widget.userId,
                                                  demand: d)),);
                                      if (result == true) _loadData();
                                    },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Modifier'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue[700])),
                                    const SizedBox(width: 8),
                                    TextButton.icon(onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            AlertDialog(title: const Text(
                                                'Confirmer la suppression'),
                                              content: const Text(
                                                  'Êtes-vous sûr de vouloir supprimer cette demande de stage ?'),
                                              actions: [
                                                TextButton(onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                    child: const Text(
                                                        'Annuler')),
                                                ElevatedButton(onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                        backgroundColor: Colors
                                                            .red,
                                                        foregroundColor: Colors
                                                            .white),
                                                    child: const Text(
                                                        'Supprimer')),
                                              ],),);
                                      if (confirm == true) {
                                        await _service.deleteInternshipDemand(
                                            d.id!);
                                        if (mounted) {
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Demande supprimée')));
                                          _loadData();
                                        }
                                      }
                                    },
                                        icon: const Icon(
                                            Icons.delete, size: 18),
                                        label: const Text('Supprimer'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red)),
                                  ] else
                                    // Enterprise users: read-only + can respond
                                    ...[
                                      TextButton.icon(onPressed: () =>
                                          _showEnterpriseDetailDialog(d),
                                          icon: const Icon(
                                              Icons.visibility, size: 18),
                                          label: const Text('Voir'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors
                                                  .blueGrey)),
                                      const SizedBox(width: 8),
                                      TextButton.icon(onPressed: () =>
                                          _showRespondDialog(d),
                                          icon: const Icon(
                                              Icons.reply, size: 18),
                                          label: const Text('Répondre'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.green)),
                                    ]
                                ]),
                          ],
                        ),
                      )));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEnterprise ? null : FloatingActionButton
          .extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
                demand_form.InternshipDemandFormScreen(userId: widget.userId)),
          );
          if (result == true) _loadData();
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showEnterpriseDetailDialog(InternshipDemand d) {
    // Load user / jobseeker details then show dialog
    () async {
      final user = await _userService.getUserById(d.userId);
      final jobSeeker = await _userService.getJobSeekerByUserId(d.userId);

      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text(d.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null) ...[
                      Text('Candidat: ${user.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Email: ${user.email}'),
                      if (user.phone != null && user.phone!.isNotEmpty) Text(
                          'Téléphone: ${user.phone}'),
                      const SizedBox(height: 12),
                    ],
                    if (jobSeeker != null) ...[
                      if (jobSeeker.cvDescription.isNotEmpty) ...[
                        const Text('À propos du CV:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(jobSeeker.cvDescription),
                        const SizedBox(height: 8),
                      ],
                      if (jobSeeker.resumeUrl.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(child: Text(
                                'CV: ${jobSeeker.resumeUrl}', maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                            IconButton(onPressed: () async {
                              // try to open resume URL or local file
                              final url = jobSeeker.resumeUrl;
                              if (url.startsWith('http')) {
                                // Open via url_launcher if available; fallback to showing text
                                try {
                                  // ignore: depend_on_referenced_packages
                                  await launchUrl(Uri.parse(url));
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text(
                                          'Impossible d\'ouvrir le CV')));
                                }
                              } else {
                                await _openAttachment(jobSeeker.resumeUrl);
                              }
                            }, icon: const Icon(Icons.open_in_new)),
                            const SizedBox(width: 6),
                            // Parse CV button
                            IconButton(onPressed: () async {
                              // Parse the resume using AI
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analyse du CV en cours...')));
                              try {
                                final parsed = await CvParserService.instance.parseCvFileAndSave(demandId: d.id!, filePath: jobSeeker.resumeUrl, parsedBy: widget.userId);
                                if (parsed == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune donnée extraite du CV. Vérifiez le format du fichier ou la configuration de parsing.')));
                                  return;
                                }
                                // show results
                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                  title: const Text('Résultats de l\'analyse'),
                                  content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    if (parsed.contactEmail != null) Text('Email: ${parsed.contactEmail}'),
                                    if (parsed.contactPhone != null) Text('Phone: ${parsed.contactPhone}'),
                                    const SizedBox(height: 8),
                                    const Text('Compétences techniques:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Wrap(children: (parsed.technicalSkills ?? []).map((s) => Padding(padding: const EdgeInsets.all(4.0), child: Chip(label: Text(s)))).toList()),
                                    const SizedBox(height: 8),
                                    const Text('Compétences non-techniques:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Wrap(children: (parsed.nonTechnicalSkills ?? []).map((s) => Padding(padding: const EdgeInsets.all(4.0), child: Chip(label: Text(s)))).toList()),
                                    const SizedBox(height: 8),
                                    const Text('Résumé:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (parsed.summary != null) Text(parsed.summary!),
                                  ])),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                ));
                              } on Exception catch (e) {
                                final err = e.toString();
                                // If extraction failed, try rendering first page preview
                                if (err.contains('extract_failed')) {
                                  final fileToShow = jobSeeker.resumeUrl;
                                  Uint8List? img;
                                  try {
                                    img = await CvParserService.instance.renderFirstPageAsImage(fileToShow);
                                  } catch (_) { img = null; }
                                  showDialog(context: context, builder: (ctx) => AlertDialog(
                                    title: const Text('Impossible d\'extraire le texte'),
                                    content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Le PDF semble contenir une image (scan) ou le texte n\'a pas pu être extrait.'),
                                      const SizedBox(height: 8),
                                      if (img != null) ...[Center(child: Image.memory(img, width: 300)), const SizedBox(height: 8)],
                                      const Text('Options:'),
                                      const Text('- Téléversez un .txt du CV pour un test rapide'),
                                      const Text('- Activez une conversion serveur-side ou utilisez OCR si nécessaire'),
                                      const SizedBox(height: 8),
                                      Text('Détails: $err', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ])),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                  ));
                                } else {
                                  showDialog(context: context, builder: (ctx) => AlertDialog(
                                    title: const Text('Erreur lors de l\'analyse'),
                                    content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(err),
                                      const SizedBox(height: 12),
                                      const Text('Vérifiez :', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      const Text('- La clé OPENAI_API_KEY est définie (ex: run avec --dart-define=OPENAI_API_KEY=sk-...)'),
                                      const Text('- Pour tester rapidement, uploadez un fichier .txt contenant le contenu du CV'),
                                    ])),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                  ));
                                }
                              } catch (e) {
                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                  title: const Text('Erreur inconnue lors de l\'analyse'),
                                  content: Text(e.toString()),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                ));
                              }
                            }, icon: const Icon(Icons.smart_toy, color: Colors.deepPurple)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],

                    Text(d.description),
                    const SizedBox(height: 12),
                    Text('Durée: ${d.duration}'),
                    const SizedBox(height: 8),
                    if (d.attachments != null && d.attachments!.isNotEmpty) ...[
                      const Text('Fichiers joints:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...d.attachments!.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: Text(p.basename(a), style: const TextStyle(fontSize: 14))),
                                IconButton(
                                  tooltip: 'Ouvrir',
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  onPressed: () => _openAttachment(a),
                                ),
                                IconButton(
                                  tooltip: 'Télécharger',
                                  icon: const Icon(Icons.download_rounded, size: 20),
                                  onPressed: () => _downloadAttachment(a),
                                ),
                                // Parse (AI) button for this attachment
                                IconButton(
                                  tooltip: 'Analyser (AI)',
                                  icon: const Icon(Icons.smart_toy, size: 20, color: Colors.deepPurple),
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analyse du fichier en cours...')));
                                    try {
                                      // If attachment is a URL, CvParserService will download it; otherwise it will read local file
                                      final parsed = await CvParserService.instance.parseCvFileAndSave(demandId: d.id!, filePath: a, parsedBy: widget.userId);
                                      if (parsed == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune donnée extraite du fichier. Vérifiez le format ou la configuration.')));
                                        return;
                                      }
                                      showDialog(context: context, builder: (ctx) => AlertDialog(
                                        title: const Text('Résultats de l\'analyse'),
                                        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          if (parsed.contactEmail != null) Text('Email: ${parsed.contactEmail}'),
                                          if (parsed.contactPhone != null) Text('Phone: ${parsed.contactPhone}'),
                                          const SizedBox(height: 8),
                                          const Text('Compétences techniques:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Wrap(children: (parsed.technicalSkills ?? []).map((s) => Padding(padding: const EdgeInsets.all(4.0), child: Chip(label: Text(s)))).toList()),
                                          const SizedBox(height: 8),
                                          const Text('Compétences non-techniques:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Wrap(children: (parsed.nonTechnicalSkills ?? []).map((s) => Padding(padding: const EdgeInsets.all(4.0), child: Chip(label: Text(s)))).toList()),
                                          const SizedBox(height: 8),
                                          const Text('Résumé:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          if (parsed.summary != null) Text(parsed.summary!),
                                        ])),
                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                      ));
                                    } on Exception catch (e) {
                                      final err = e.toString();
                                      if (err.contains('extract_failed')) {
                                        Uint8List? img;
                                        try { img = await CvParserService.instance.renderFirstPageAsImage(a); } catch (_) { img = null; }
                                        showDialog(context: context, builder: (ctx) => AlertDialog(
                                          title: const Text('Impossible d\'extraire le texte'),
                                          content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            const Text('Le fichier semble être une image (scan) ou le texte n\'a pas pu être extrait.'),
                                            const SizedBox(height: 8),
                                            if (img != null) ...[Center(child: Image.memory(img, width: 300)), const SizedBox(height: 8)],
                                            const Text('Options:'),
                                            const Text('- Téléversez un .txt du CV pour un test rapide'),
                                            const Text('- Activez une conversion serveur-side ou utilisez OCR si nécessaire'),
                                            const SizedBox(height: 8),
                                            Text('Détails: $err', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ])),
                                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                                        ));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'analyse: $err')));
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'analyse: $e')));
                                    }
                                  },
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer')),
              ],
            ),
      );
    }
    ();
  }

  Future<void> _openAttachment(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier introuvable')));
        return;
      }
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: $e')));
    }
  }

  Future<void> _downloadAttachment(String path) async {
    try {
      final src = File(path);
      if (!await src.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier introuvable')));
        return;
      }

      Directory? downloadsDir;
      try {
        // Request storage permission for Android when writing to external downloads
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            // If not granted, try manageExternalStorage (Android 11+); if still not granted, we'll fallback
            final mgr = await Permission.manageExternalStorage.request();
            if (!mgr.isGranted) {
              downloadsDir = null;
            }
          }
        }
        final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) downloadsDir = dirs.first;
      } catch (_) {
        downloadsDir = null;
      }

      if (downloadsDir == null) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final destPath = p.join(downloadsDir.path, p.basename(path));
      final dest = File(destPath);
      await dest.create(recursive: true);
      await src.copy(dest.path);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier téléchargé: ${dest.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')));
    }
  }

  Map<String, int> _buildStatusCount() {
    final map = <String, int>{};
    for (var d in _items) {
      map[d.status] = (map[d.status] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _exportPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préparation du PDF...')));
      await _service.exportDemandsAsPdf(
          _filtered.isNotEmpty ? _filtered : _items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export PDF: $e')));
    }
  }

  Future<void> _exportCsv() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préparation du CSV...')));
      await _service.exportDemandsAsCsv(
          _filtered.isNotEmpty ? _filtered : _items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export CSV: $e')));
    }
  }

  void _showRespondDialog(InternshipDemand d) {
    final _feedbackController = TextEditingController(text: d.feedback ?? '');
    String selected = d.status;
    showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Répondre à la demande'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: ['Accepté', 'Refusé', 'En cours', 'À discuter']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => selected = v ?? selected,
                  decoration: const InputDecoration(
                      labelText: 'Nouveau statut'),
                ),
                const SizedBox(height: 12),
                TextField(controller: _feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Feedback (optionnel)')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler')),
              ElevatedButton(onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Envoi en cours...')));
                final success = await _service.changeStatus(
                    d.id!, selected, feedback: _feedbackController.text.trim());
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Réponse enregistrée')));
                    _loadData();
                  }
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Échec lors de l\'enregistrement')));
                }
              }, child: const Text('Envoyer')),
            ],
          ),
    );
  }
}

