import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/auth_role_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class PendingScheduleScreen extends StatefulWidget {
  final String date;
  const PendingScheduleScreen({super.key, required this.date});

  @override
  State<PendingScheduleScreen> createState() => _PendingScheduleScreenState();
}

class _PendingScheduleScreenState extends State<PendingScheduleScreen> {
  final _firestore = FirestoreService();
  final _roleService = const AuthRoleService();
  bool _isActing = false;

  Future<void> _approve(Map<String, dynamic> data) async {
    setState(() => _isActing = true);
    try {
      await _firestore.approvePendingSchedule(widget.date);
      // Write a notification document — the Cloud Function watches this
      // collection and sends the FCM push to all_users topic.
      await _firestore.writeNotification({
        'title': '✅ Schedule Updated',
        'body': 'The bus schedule for ${widget.date} is now live.',
        'date': widget.date,
        'type': 'schedule_live',
        'status': 'approved',
        'createdAt': DateTime.now(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isActing = true);
    try {
      await _firestore.rejectPendingSchedule(widget.date);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Schedule',
          style: TextStyle(
              color: theme.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.getPendingSchedule(widget.date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _EmptyState(theme: theme, date: widget.date);
          }

          final data = snapshot.data!.data()!;

          return FutureBuilder<bool>(
            future: _roleService.isAdmin(),
            builder: (context, adminSnap) {
              final isAdmin = adminSnap.data ?? false;
              return _ScheduleBody(
                theme: theme,
                date: widget.date,
                data: data,
                isAdmin: isAdmin,
                isActing: _isActing,
                onApprove: () => _approve(data),
                onReject: _reject,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Schedule body ─────────────────────────────────────────────────────────────

class _ScheduleBody extends StatelessWidget {
  final AppThemeData theme;
  final String date;
  final Map<String, dynamic> data;
  final bool isAdmin;
  final bool isActing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ScheduleBody({
    required this.theme,
    required this.date,
    required this.data,
    required this.isAdmin,
    required this.isActing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final routes = (data['routes'] as List<dynamic>?) ?? [];
    final extractedFrom =
        data['extractedFrom'] as String? ?? 'email_body';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        // ── Pending banner ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700)),
          ),
          child: Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This schedule is awaiting admin approval',
                  style: TextStyle(
                    color: const Color(0xFF856404),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Date & meta ──────────────────────────────────────────────────
        Text(
          date,
          style: TextStyle(
              color: theme.text,
              fontSize: 22,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.source_rounded, size: 14, color: theme.subText),
            const SizedBox(width: 4),
            Text(
              extractedFrom == 'pdf_attachment'
                  ? 'Extracted from PDF attachment'
                  : 'Extracted from email body',
              style: TextStyle(color: theme.subText, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Routes ───────────────────────────────────────────────────────
        if (routes.isEmpty)
          Center(
            child: Text('No route data found.',
                style: TextStyle(color: theme.subText)),
          )
        else
          ...routes.map((r) => _RouteCard(
                theme: theme,
                routeData: r as Map<String, dynamic>,
              )),

        // ── Admin action buttons ─────────────────────────────────────────
        if (isAdmin) ...[
          const SizedBox(height: 8),
          if (isActing)
            Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white),
                label: const Text('Approve & Apply',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFD32F2F)),
                label: const Text('Reject',
                    style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ── Route card ────────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final AppThemeData theme;
  final Map<String, dynamic> routeData;
  const _RouteCard({required this.theme, required this.routeData});

  @override
  Widget build(BuildContext context) {
    final name = routeData['route_name'] as String? ?? 'Route';
    final stops = (routeData['stops'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route name header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.route_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Stops list
          ...stops.asMap().entries.map((entry) {
            final stop = entry.value as Map<String, dynamic>;
            final isLast = entry.key == stops.length - 1;
            return _StopRow(
              theme: theme,
              stopName: stop['stop_name'] as String? ?? '',
              time: stop['time'] as String? ?? '',
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

// ── Stop row ──────────────────────────────────────────────────────────────────

class _StopRow extends StatelessWidget {
  final AppThemeData theme;
  final String stopName;
  final String time;
  final bool isLast;
  const _StopRow({
    required this.theme,
    required this.stopName,
    required this.time,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stopName,
              style: TextStyle(color: theme.text, fontSize: 14),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: theme.subText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / not-found state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppThemeData theme;
  final String date;
  const _EmptyState({required this.theme, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: theme.subText),
            const SizedBox(height: 16),
            Text(
              'No Pending Schedule',
              style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending schedule found for $date.\nIt may have already been approved or rejected.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: theme.subText, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
