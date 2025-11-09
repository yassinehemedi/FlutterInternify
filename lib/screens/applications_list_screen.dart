
import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../services/offer_service.dart';
import '../services/UserService.dart';
import '../services/email_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
// imports trimmed
import '../theme/app_theme.dart';

class ApplicationsListScreen extends StatefulWidget {
  final int offerId;
  const ApplicationsListScreen({super.key, required this.offerId});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  List<ApplicationModel> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final apps = await ApplicationService.instance.getApplicationsByOfferId(widget.offerId);
    setState(() {
      _apps = apps;
      _isLoading = false;
    });
  }

  Future<String> _getUserName(int userId) async {
    final user = await UserService.instance.getUserById(userId);
    return user?.name ?? 'Unknown';
  }

  Future<void> _updateStatus(ApplicationModel app, String status) async {
    final updated = app.copyWith(status: status);
    await ApplicationService.instance.updateApplication(updated);
    // send email to applicant informing them of decision
    String offerTitle = 'the offer';
    try {
      final user = await UserService.instance.getUserById(app.userId);
      // fetch offer title
      try {
        final o = await OfferService.instance.getOfferById(app.offerId);
        if (o != null) offerTitle = o.title;
      } catch (_) {}

      if (user != null && user.email.isNotEmpty) {
        await EmailService.sendApplicationStatusEmail(
          recipientEmail: user.email,
          recipientName: user.name,
          offerTitle: offerTitle,
          status: status,
        );
      }
    } catch (e) {
      // ignore email failures for now
    }

    // create in-app notification for the applicant
    try {
      final n = NotificationModel(
        title: 'Application $status',
        body: 'Your application for "$offerTitle" has been $status.',
        createdAt: DateTime.now(),
        recipientId: app.userId,
        offerId: widget.offerId,
      );
      await NotificationService.instance.createNotification(n);
    } catch (e) {
      // ignore
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications'), backgroundColor: AppTheme.primaryBlue),
      body: Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _apps.isEmpty
                ? const Center(child: Text('No applications yet'))
                : ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: _getUserName(app.userId),
                                builder: (context, snap) {
                                  final name = snap.data ?? 'Loading...';
                                  return Text(name, style: const TextStyle(fontWeight: FontWeight.bold));
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(app.motivationalMessage ?? ''),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (app.cvFile != null)
                                    TextButton.icon(
                                      onPressed: () {
                                        // Opening file: just show path for now
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('CV path'),
                                            content: Text(app.cvFile!),
                                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('View CV'),
                                    ),
                                  const Spacer(),
                                  Text(app.status, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: app.status == 'Approved' ? null : () => _updateStatus(app, 'Approved'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Approve'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: app.status == 'Denied' ? null : () => _updateStatus(app, 'Denied'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Deny'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
