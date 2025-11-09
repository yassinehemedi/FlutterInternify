import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';
import '../services/offer_service.dart';
import '../services/application_service.dart';
import 'offer_form_screen.dart';
import '../theme/app_theme.dart';
import 'application_form_screen.dart';
import 'applications_list_screen.dart';
import '../services/comment_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../services/SentimentAnalysisService.dart';
import '../services/comment_report_service.dart';
import '../models/comment_report_model.dart';
import '../models/comment_model.dart';
import '../services/UserService.dart';

class OfferDetailScreen extends StatefulWidget {
  final Offer offer;
  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _isDeleting = false;
  int? _currentUserId;
  String? _currentUserRole;
  List<CommentModel> _comments = [];
  final Map<int, String> _usernames = {};
  final Map<int, bool> _hasReported = {};
  List<ApplicationModel> _applications = [];
  bool _loadingApplications = true;
  final _commentController = TextEditingController();
  bool _loadingComments = true;

  Future<void> _loadApplications() async {
    setState(() => _loadingApplications = true);
    final apps = await ApplicationService.instance
        .getApplicationsByOfferId(widget.offer.idOffer!);
    // optionally preload applicant names
    for (final a in apps) {
      if (!_usernames.containsKey(a.userId)) {
        final u = await UserService.instance.getUserById(a.userId);
        _usernames[a.userId] = u?.name ?? 'User';
      }
    }
    setState(() {
      _applications = apps;
      _loadingApplications = false;
    });
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isDeleting = true);
    await OfferService.instance.deleteOffer(widget.offer.idOffer!);
    setState(() => _isDeleting = false);
    Navigator.pop(context, true);
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Offer?>(
      context,
      MaterialPageRoute(
          builder: (context) => OfferFormScreen(
              userId: widget.offer.userId, offer: widget.offer)),
    );
    if (updated != null) Navigator.pop(context, updated);
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('currentUserId');
    setState(() => _currentUserId = uid);
    if (uid != null) {
      final user = await UserService.instance.getUserById(uid);
      setState(() => _currentUserRole = user?.role);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    final comments = await CommentService.instance
        .getCommentsByOfferId(widget.offer.idOffer!);
    // preload usernames for commenters
    for (final c in comments) {
      if (!_usernames.containsKey(c.userId)) {
        final u = await UserService.instance.getUserById(c.userId);
        _usernames[c.userId] = u?.name ?? 'User';
      }
      // check whether current user has already reported this comment
      if (_currentUserId != null && c.idComment != null) {
        final rep = await CommentReportService.instance
            .hasUserReported(c.idComment!, _currentUserId!);
        _hasReported[c.idComment!] = rep;
      }
    }
    setState(() {
      _comments = comments;
      _loadingComments = false;
    });
  }

  Future<void> _addComment() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to comment')));
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    // Basic local profanity check (small list). For stronger checks we use LLM service.
    final badWords = ['fuck', 'shit', 'bitch', 'asshole', 'damn', 'idiot'];
    final lower = text.toLowerCase();
    for (final w in badWords) {
      if (lower.contains(w)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please avoid offensive language in comments')));
        return;
      }
    }

    // Use SentimentAnalysisService to detect negative/offensive content (if configured)
    try {
      final analysis = await SentimentAnalysisService.analyzeSentiment(text);
      final sentiment =
          (analysis['sentiment'] ?? 'neutral').toString().toLowerCase();
      if (sentiment == 'negative') {
        // Block negative/offensive comments
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Your comment looks offensive or negative and cannot be posted')));
        return;
      }
    } catch (e) {
      // If analysis fails, proceed with posting (fail-open) but log
      debugPrint('Sentiment check failed: $e');
    }

    final comment = CommentModel(
        commentContent: text,
        userId: _currentUserId!,
        offerId: widget.offer.idOffer!);
    await CommentService.instance.createComment(comment);
    _commentController.clear();
    await _loadComments();
    // create an in-app notification for the enterprise owner of the offer
    try {
      final recipientId = widget.offer.userId;
      if (recipientId != _currentUserId) {
        final me = await UserService.instance.getUserById(_currentUserId!);
        final title = 'New comment on your offer';
        final body =
            '${me?.name ?? 'Someone'} commented on "${widget.offer.title}"';
        final n = NotificationModel(
          title: title,
          body: body,
          createdAt: DateTime.now(),
          recipientId: recipientId,
          offerId: widget.offer.idOffer,
        );
        await NotificationService.instance.createNotification(n);
      }
    } catch (e) {
      // ignore notification failures to preserve UX
    }
  }

  Future<void> _editComment(CommentModel comment) async {
    if (_currentUserId == null || _currentUserId != comment.userId) return;
    final controller = TextEditingController(text: comment.commentContent);
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (res != null && res.trim().isNotEmpty) {
      final updated = comment.copyWith(commentContent: res.trim());
      await CommentService.instance.updateComment(updated);
      await _loadComments();
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    if (_currentUserId == null || _currentUserId != comment.userId) return;
    final conf = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Delete this comment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (conf == true) {
      await CommentService.instance.deleteComment(comment.idComment!);
      await _loadComments();
    }
  }

  Future<void> _reportComment(CommentModel comment) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to report')));
      return;
    }
    if (comment.idComment == null) return;
    final already = await CommentReportService.instance
        .hasUserReported(comment.idComment!, _currentUserId!);
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have already reported this comment')));
      return;
    }
    final report = CommentReport(
        commentId: comment.idComment!, reporterId: _currentUserId!);
    await CommentReportService.instance.createReport(report);
    // refresh comments; comment may be deleted if reports reached threshold
    await _loadComments();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Comment reported')));
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          if (_currentUserId != null &&
              _currentUserId == widget.offer.userId) ...[
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.image != null && offer.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(offer.image!),
                    width: double.infinity, height: 220, fit: BoxFit.cover),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.work_outline, size: 64)),
              ),
            const SizedBox(height: 12),
            Text(offer.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(offer.category ?? '',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text(offer.description ?? ''),
            const SizedBox(height: 20),
            if (_isDeleting) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            // Actions: Apply (job seeker) or View Applications (enterprise owner)
            Row(
              children: [
                if (_currentUserRole == 'job_seeker')
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please login first')));
                        return;
                      }
                      final created = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ApplicationFormScreen(
                                userId: _currentUserId!,
                                offerId: offer.idOffer!)),
                      );
                      if (created != null) {
                        // Optionally show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Application submitted')));
                        // create a notification for the enterprise owner
                        try {
                          final recipientId = widget.offer.userId;
                          if (recipientId != _currentUserId) {
                            final me = await UserService.instance
                                .getUserById(_currentUserId!);
                            final title = 'New application received';
                            final body =
                                '${me?.name ?? 'Someone'} applied to "${widget.offer.title}"';
                            final n = NotificationModel(
                              title: title,
                              body: body,
                              createdAt: DateTime.now(),
                              recipientId: recipientId,
                              offerId: widget.offer.idOffer,
                            );
                            await NotificationService.instance
                                .createNotification(n);
                          }
                        } catch (e) {
                          // ignore notification failure
                        }
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue),
                  ),
                const SizedBox(width: 12),
                if (_currentUserRole == 'enterprise' &&
                    _currentUserId == offer.userId)
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Open applications list
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ApplicationsListScreen(
                                offerId: offer.idOffer!)),
                      );
                      await _loadComments();
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Applications'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            // If job seeker, show their application (if any) with edit/delete
            if (_currentUserRole == 'job_seeker')
              _loadingApplications
                  ? const SizedBox.shrink()
                  : Builder(builder: (context) {
                      ApplicationModel? myApp;
                      for (final a in _applications) {
                        if (a.userId == _currentUserId) {
                          myApp = a;
                          break;
                        }
                      }
                      if (myApp == null) return const SizedBox.shrink();
                      final _myApp = myApp; // promote for closures
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Application',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(myApp.motivationalMessage ?? ''),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (_myApp.cvFile != null)
                                    TextButton.icon(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                            title: const Text('CV path'),
                                            content: Text(_myApp.cvFile!),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Close'))
                                            ]),
                                      ),
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('View CV'),
                                    ),
                                  const Spacer(),
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final updated = await Navigator.push<
                                                ApplicationModel?>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (c) =>
                                                    ApplicationFormScreen(
                                                        userId: _currentUserId!,
                                                        offerId: widget
                                                            .offer.idOffer!,
                                                        application: _myApp)));
                                        if (updated != null)
                                          await _loadApplications();
                                      }),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final conf = await showDialog<bool?>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Withdraw application'),
                                            content: const Text(
                                                'Are you sure you want to withdraw your application?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Delete'))
                                            ],
                                          ),
                                        );
                                        if (conf == true) {
                                          await ApplicationService.instance
                                              .deleteApplication(
                                                  _myApp.idApplication!);
                                          await _loadApplications();
                                        }
                                      }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            // Comments section
            const Text('Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loadingComments)
              const Center(child: CircularProgressIndicator())
            else if (_comments.isEmpty)
              const Text('No comments yet')
            else
              Column(
                children: _comments.map((c) {
                  final username = _usernames[c.userId] ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                        child: Text(username.isNotEmpty
                            ? username[0].toUpperCase()
                            : 'U')),
                    title: Text(username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(c.commentContent),
                        const SizedBox(height: 6),
                        Text(c.createdAt.toLocal().toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing:
                        (_currentUserId != null && _currentUserId == c.userId)
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editComment(c)),
                                IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteComment(c)),
                              ])
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: Icon(Icons.flag,
                                      size: 20,
                                      color: (c.idComment != null &&
                                              _hasReported[c.idComment] == true)
                                          ? Colors.red
                                          : null),
                                  onPressed: (c.idComment == null ||
                                          _currentUserId == null)
                                      ? null
                                      : () => _reportComment(c),
                                ),
                              ]),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Form(
              key: GlobalKey<FormState>(),
              child: TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a comment')));
                          return;
                        }
                        _addComment();
                      }),
                ),
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadComments();
    _loadApplications();
  }
}
