import 'dart:io';

import 'package:flutter/material.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import 'offer_form_screen.dart';
import 'offer_detail_screen.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';

class OffersListScreen extends StatefulWidget {
  final int userId; // current user id (to create offers)
  const OffersListScreen({super.key, required this.userId});

  @override
  State<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen>
    with WidgetsBindingObserver {
  List<Offer> _offers = [];
  List<Offer> _displayedOffers = [];
  List<String> _categories = [];
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _loadOffers();
    _loadUnread();
  }

  Future<void> _loadUserRole() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('users',
          columns: ['role'], where: 'id = ?', whereArgs: [widget.userId]);
      setState(() =>
      _userRole = rows.isNotEmpty ? (rows.first['role'] as String?) : null);
    } catch (e) {
      setState(() => _userRole = null);
    }
  }

  Future<void> _loadUnread() async {
    try {
      final c =
      await NotificationService.instance.getUnreadCount(widget.userId);
      setState(() => _unreadNotifications = c);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    // purge expired offers first (ensures offers with past expiry are removed)
    try {
      await DatabaseHelper.instance.purgeExpiredOffers();
    } catch (e) {
      // ignore purge errors
    }
    final offers = await OfferService.instance.getAllOffers();
    setState(() {
      _offers = offers;
      _categories = _offers
          .map((e) => e.category ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      _categories.sort();
      _displayedOffers = List.of(_offers);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes (e.g., after changing emulator system date), refresh and purge
    if (state == AppLifecycleState.resumed) {
      _loadOffers();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _displayedOffers = _offers.where((o) {
        final matchesSearch = q.isEmpty ||
            o.title.toLowerCase().contains(q) ||
            (o.description ?? '').toLowerCase().contains(q);
        final matchesCategory = _selectedCategory == null ||
            _selectedCategory!.isEmpty ||
            (o.category ?? '') == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCreate() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => OfferFormScreen(userId: widget.userId),
      ),
    );
    if (result != null) await _loadOffers();
  }

  void _onTapOffer(Offer offer) async {
    final updated = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => OfferDetailScreen(offer: offer)),
    );
    if (updated != null) await _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) =>
                          NotificationsScreen(currentUserId: widget.userId)));
              await _loadUnread();
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text('$_unreadNotifications',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
      (_userRole != null && _userRole!.toLowerCase() == 'enterprise')
          ? FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: _onCreate,
        child: const Icon(Icons.add),
      )
          : null,
      body: Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _offers.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No offers yet',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue),
                onPressed: _onCreate,
                child: const Text('Create your first offer'),
              )
            ],
          ),
        )
            : Column(
          children: [
            // Search and category filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search offers...'),
                    onChanged: (v) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('All'))
                  ] +
                      _categories
                          .map((c) => DropdownMenuItem(
                          value: c, child: Text(c)))
                          .toList(),
                  onChanged: (v) {
                    setState(() =>
                    _selectedCategory = v == '' ? null : v);
                    _applyFilter();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _displayedOffers.length,
                itemBuilder: (context, index) {
                  final offer = _displayedOffers[index];
                  return GestureDetector(
                    onTap: () => _onTapOffer(offer),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (offer.image != null &&
                                offer.image!.isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(8),
                                child: Image.file(
                                  File(offer.image!),
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withOpacity(0.2),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.work_outline,
                                    size: 36,
                                    color: AppTheme.primaryBlue),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(offer.title,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(
                                    offer.category ?? '',
                                    style: const TextStyle(
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    offer.description ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}