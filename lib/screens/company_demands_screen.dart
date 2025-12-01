// filepath: lib/screens/company_demands_screen.dart
import 'package:flutter/material.dart';
import '../models/internship_demand.dart';
import '../services/internship_demand_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class CompanyDemandsScreen extends StatefulWidget {
  final int companyId;
  const CompanyDemandsScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  State<CompanyDemandsScreen> createState() => _CompanyDemandsScreenState();
}

class _CompanyDemandsScreenState extends State<CompanyDemandsScreen> {
  final InternshipDemandService _service = InternshipDemandService();
  List<InternshipDemand> _items = [];
  bool _isLoading = true;
  String _statusFilter = 'Tous';
  String _search = '';
  String _domainFilter = '';
  int? _studentIdFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _items = await _service.getForCompany(
      widget.companyId,
      status: _statusFilter == 'Tous' ? null : _statusFilter,
      searchQuery: _search,
      domain: _domainFilter.isEmpty ? null : _domainFilter,
      studentId: _studentIdFilter,
      sortBy: _sortBy,
    );
    setState(() => _isLoading = false);
  }

  Future<void> _changeStatus(InternshipDemand d, String status) async {
    final controller = TextEditingController();
    final feedback = await showDialog<String?>(context: context, builder: (context) => AlertDialog(title: Text('Feedback (optionnel)'), content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Commentaires')), actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Annuler')), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Envoyer'))]));
    final ok = await _service.changeStatus(d.id!, status, feedback: feedback);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
      _load();
    }
  }

  String _sortBy = 'date_desc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes reçues'), backgroundColor: Colors.blue[700]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(hintText: 'Rechercher...'),
                          onChanged: (v) {
                            _search = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'En cours', child: Text('En cours')),
                          DropdownMenuItem(value: 'Acceptée', child: Text('Acceptée')),
                          DropdownMenuItem(value: 'Rejetée', child: Text('Rejetée')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _statusFilter = v ?? 'Tous';
                          });
                          _load();
                        },
                      ),
                      IconButton(onPressed: _load, icon: const Icon(Icons.search)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(value: _sortBy, items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Date ↓')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Date ↑')),
                      ], onChanged: (v) { setState(() { _sortBy = v ?? 'date_desc'; }); _load(); }),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () async { await _service.exportDemandsAsPdf(_items); }, icon: const Icon(Icons.picture_as_pdf)),
                      IconButton(onPressed: () async { await _service.exportDemandsAsCsv(_items); }, icon: const Icon(Icons.table_chart)),
                    ],
                  ),
                ),
                // domain / student filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Expanded(child: TextField(decoration: const InputDecoration(hintText: 'Domaine (ex: Technique)'), onChanged: (v) { _domainFilter = v; }),),
                    const SizedBox(width: 8),
                    SizedBox(width: 120, child: TextField(decoration: const InputDecoration(hintText: 'Student ID'), keyboardType: TextInputType.number, onChanged: (v) { _studentIdFilter = int.tryParse(v); })),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _load, child: const Text('Filtrer'))
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final d = _items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(d.title),
                          subtitle: Text('${d.userId} • ${d.duration} • ${d.status}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => _changeStatus(d, v),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'Acceptée', child: Text('Accepter')),
                              PopupMenuItem(value: 'Rejetée', child: Text('Rejeter')),
                            ],
                          ),
                          onTap: () async {
                            // view details dialog
                            await showDialog(
                              context: context,
                              builder: (c) {
                                return AlertDialog(
                                  title: Text(d.title),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Description:'),
                                        const SizedBox(height: 4),
                                        Text(d.description),
                                        const SizedBox(height: 8),
                                        const Text('Attachments:'),
                                        const SizedBox(height: 4),
                                        if (d.attachments == null || d.attachments!.isEmpty)
                                          const Text('- Aucun fichier joint -')
                                        else
                                          ...d.attachments!.map((a) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: InkWell(
                                                  onTap: () async {
                                                    try {
                                                      if (a.startsWith('http') || a.startsWith('https')) {
                                                        final uri = Uri.tryParse(a);
                                                        if (uri != null && await canLaunchUrl(uri)) {
                                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                          return;
                                                        }
                                                      }

                                                      // Treat as local file path
                                                      final file = File(a);
                                                      if (await file.exists()) {
                                                        await OpenFile.open(file.path);
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le fichier')));
                                                      }
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le fichier')));
                                                    }
                                                  },
                                                  child: Text(a, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                                                ),
                                              )),
                                        const SizedBox(height: 8),
                                        Text('Feedback: ${d.feedback ?? '-'}'),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer')),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
