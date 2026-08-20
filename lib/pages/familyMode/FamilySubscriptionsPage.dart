import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/pages/familyMode/AddFamilySubscriptionPage.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared recurring bills — Netflix, electricity, the family phone plan.
class FamilySubscriptionsPage extends StatefulWidget {
  const FamilySubscriptionsPage({super.key, required this.family});

  final Family family;

  @override
  State<FamilySubscriptionsPage> createState() =>
      _FamilySubscriptionsPageState();
}

class _FamilySubscriptionsPageState extends State<FamilySubscriptionsPage> {
  static const Color _accent = Color(0xFFE67E22);
  static const Color _purple = Color(0xFF9B59B6);

  final FamilyFirestoreService _service = FamilyFirestoreService();

  String get _currency => CurrencyService.getCurrencySymbolSync();

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleActive(FamilySubscription subscription) async {
    try {
      await _service.setSubscriptionActive(
        familyId: widget.family.id,
        subscriptionId: subscription.id,
        isActive: !subscription.isActive,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not update that subscription.');
    }
  }

  Future<void> _delete(FamilySubscription subscription) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Delete subscription',
      message: '"${subscription.name}" will be removed for the whole family.',
      confirmText: 'Delete',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await _service.deleteSubscription(
        familyId: widget.family.id,
        subscriptionId: subscription.id,
      );
      if (!mounted) return;
      _showSnack('Subscription deleted.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not delete that subscription.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Family Subscriptions',
        subtitle: widget.family.name,
        useCustomDesign: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddFamilySubscriptionPage(family: widget.family),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<FamilySubscription>>(
          stream: _service.getSubscriptions(widget.family.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final subscriptions =
                snapshot.data ?? const <FamilySubscription>[];
            final active = subscriptions.where((s) => s.isActive).toList();
            final paused = subscriptions.where((s) => !s.isActive).toList();

            final monthlyTotal =
                active.fold<double>(0, (sum, s) => sum + s.monthlyEquivalent);
            final yearlyTotal = monthlyTotal * 12;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              children: [
                _buildSummaryCard(
                  monthlyTotal: monthlyTotal,
                  yearlyTotal: yearlyTotal,
                  activeCount: active.length,
                ),
                const SizedBox(height: 20),
                if (subscriptions.isEmpty)
                  _buildEmptyState()
                else ...[
                  if (active.isNotEmpty) ...[
                    const _SectionLabel('Active'),
                    const SizedBox(height: 10),
                    ...active.map(_buildTile),
                  ],
                  if (paused.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionLabel('Paused'),
                    const SizedBox(height: 10),
                    ...paused.map(_buildTile),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double monthlyTotal,
    required double yearlyTotal,
    required int activeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family recurring spend',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_currency ${monthlyTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'per month  •  $_currency ${yearlyTotal.toStringAsFixed(2)} per year',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$activeCount active '
              '${activeCount == 1 ? 'subscription' : 'subscriptions'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(FamilySubscription subscription) {
    final daysUntil = subscription.nextBillingDate
        .difference(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ))
        .inDays;

    final dueSoon =
        subscription.isActive && daysUntil >= 0 && daysUntil <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dueSoon ? const Color(0xFFFDE68A) : const Color(0xFFE8EDF2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (subscription.isActive ? _purple : Colors.grey)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.subscriptions_rounded,
                  color: subscription.isActive ? _purple : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: subscription.isActive
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF9AA3AF),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${subscription.billingCycle} • ${subscription.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_currency ${subscription.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '≈ $_currency '
                    '${subscription.monthlyEquivalent.toStringAsFixed(0)}/mo',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3AF),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF9AA3AF)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFamilySubscriptionPage(
                            family: widget.family,
                            existing: subscription,
                          ),
                        ),
                      );
                      break;
                    case 'toggle':
                      _toggleActive(subscription);
                      break;
                    case 'delete':
                      _delete(subscription);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(subscription.isActive ? 'Pause' : 'Resume'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: dueSoon
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: dueSoon
                      ? const Color(0xFFD97706)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    subscription.isActive
                        ? '${_dueLabel(daysUntil)} • '
                            '${DateFormat.yMMMd().format(subscription.nextBillingDate)}'
                        : 'Paused',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: dueSoon ? FontWeight.w700 : FontWeight.w500,
                      color: dueSoon
                          ? const Color(0xFF92400E)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Icon(
                  Icons.person_rounded,
                  size: 13,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 5),
                Text(
                  subscription.paidByName,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dueLabel(int daysUntil) {
    if (daysUntil < 0) return 'Overdue';
    if (daysUntil == 0) return 'Due today';
    if (daysUntil == 1) return 'Due tomorrow';
    return 'Due in $daysUntil days';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 46),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(39),
            ),
            child: const Icon(
              Icons.subscriptions_outlined,
              size: 34,
              color: Color(0xFF9AA3AF),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No family subscriptions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add the streaming, utility and phone bills you share.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Color(0xFF9AA3AF)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
