import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/pages/familyMode/AddFamilyTransactionPage.dart';
import 'package:finance_tracker/pages/familyMode/FamilyMembersPage.dart';
import 'package:finance_tracker/pages/familyMode/FamilyOnboardingPage.dart';
import 'package:finance_tracker/pages/familyMode/FamilySubscriptionsPage.dart';
import 'package:finance_tracker/pages/familyMode/FamilyTransactionsPage.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/familyMode/FamilyTransactionTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Family-mode home. Doubles as the gate: without a family it shows the
/// create/join flow, with one it shows the shared dashboard.
class FamilyModeBody extends StatefulWidget {
  const FamilyModeBody({
    super.key,
    required this.data,
  });

  /// The signed-in user's document from `Users` — same shape the personal and
  /// business bodies receive.
  final Map<String, dynamic> data;

  @override
  State<FamilyModeBody> createState() => _FamilyModeBodyState();
}

class _FamilyModeBodyState extends State<FamilyModeBody> {
  static const Color accent = Color(0xFFE67E22);

  final FamilyFirestoreService _service = FamilyFirestoreService();

  String get _username => widget.data['username']?.toString() ?? 'Member';
  String get _email => widget.data['email']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Family>>(
      stream: _service.getMyFamilies(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Could not load your family. Check your connection and '
                'Firestore rules for the Families collection.',
          );
        }

        final families = snapshot.data ?? const [];
        if (families.isEmpty) {
          return FamilyOnboardingPage(
            username: _username,
            email: _email,
          );
        }

        // Multi-family is out of scope for now: the first membership wins.
        return _FamilyDashboard(
          family: families.first,
          uid: uid,
          service: _service,
        );
      },
    );
  }
}

class _FamilyDashboard extends StatelessWidget {
  const _FamilyDashboard({
    required this.family,
    required this.uid,
    required this.service,
  });

  final Family family;
  final String uid;
  final FamilyFirestoreService service;

  static const Color accent = _FamilyModeBodyState.accent;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyService.getCurrencySymbolSync();
    final isAdmin = family.isAdmin(uid);

    return StreamBuilder<List<FamilyMember>>(
      stream: service.getMembers(family.id),
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? const <FamilyMember>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FamilyBalanceCard(
                family: family,
                currency: currency,
                memberCount: members.isEmpty
                    ? family.memberIds.length
                    : members.length,
                isAdmin: isAdmin,
              ),
              const SizedBox(height: 18),
              _buildQuickActions(context),
              const SizedBox(height: 22),
              if (isAdmin) ...[
                _PendingRequestsStrip(family: family, service: service),
              ],
              _SectionHeading(
                title: 'Recent family activity',
                actionLabel: 'See all',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FamilyTransactionsPage(family: family),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RecentActivity(
                family: family,
                service: service,
                currency: currency,
              ),
              const SizedBox(height: 26),
              const _SectionHeading(title: 'Who contributed what'),
              const SizedBox(height: 14),
              _MemberBreakdown(members: members, currency: currency, uid: uid),
              const SizedBox(height: 26),
              _SectionHeading(
                title: 'Family subscriptions',
                actionLabel: 'Manage',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FamilySubscriptionsPage(family: family),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SubscriptionSummary(
                family: family,
                service: service,
                currency: currency,
              ),
              const SizedBox(height: 26),
              const _SectionHeading(title: 'Family tools'),
              const SizedBox(height: 14),
              _buildTools(context, isAdmin: isAdmin),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Add Income',
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddFamilyTransactionPage(
                  family: family,
                  transactionType: 'INCOME',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Add Expense',
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEE2E2),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddFamilyTransactionPage(
                  family: family,
                  transactionType: 'EXPENSE',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTools(BuildContext context, {required bool isAdmin}) {
    final tools = <_Tool>[
      _Tool(
        title: 'Transactions',
        subtitle: 'Every family entry',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF4A90E2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyTransactionsPage(family: family),
          ),
        ),
      ),
      _Tool(
        title: 'Subscriptions',
        subtitle: 'Shared recurring bills',
        icon: Icons.subscriptions_rounded,
        color: const Color(0xFF9B59B6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilySubscriptionsPage(family: family),
          ),
        ),
      ),
      _Tool(
        title: isAdmin ? 'Members & requests' : 'Members',
        subtitle: isAdmin ? 'Approve, promote, remove' : 'Who is in the family',
        icon: Icons.groups_rounded,
        color: accent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyMembersPage(family: family),
          ),
        ),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: tools
          .map(
            (tool) => GestureDetector(
              onTap: tool.onTap,
              child: Container(
                width: (MediaQuery.of(context).size.width - 40) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tool.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tool.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Tool {
  _Tool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

/// The shared pot: combined balance, income and expense, plus the invite code.
class _FamilyBalanceCard extends StatelessWidget {
  const _FamilyBalanceCard({
    required this.family,
    required this.currency,
    required this.memberCount,
    required this.isAdmin,
  });

  final Family family;
  final String currency;
  final int memberCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFC0392B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE67E22).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Family Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$currency ${family.totalBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Income',
                        value: '$currency ${family.income.toStringAsFixed(2)}',
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Expense',
                        value: '$currency ${family.expense.toStringAsFixed(2)}',
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InviteCodeRow(
                  code: family.code,
                  memberCount: memberCount,
                  isAdmin: isAdmin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({
    required this.code,
    required this.memberCount,
    required this.isAdmin,
  });

  final String code;
  final int memberCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(content: Text('Family code $code copied.')),
                );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                '$memberCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Admin-only nudge that there are people waiting to be let in.
class _PendingRequestsStrip extends StatelessWidget {
  const _PendingRequestsStrip({required this.family, required this.service});

  final Family family;
  final FamilyFirestoreService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyJoinRequest>>(
      stream: service.getPendingRequests(family.id),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <FamilyJoinRequest>[];
        if (requests.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyMembersPage(family: family),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded,
                      color: Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      requests.length == 1
                          ? '${requests.first.username} wants to join as '
                              '${requests.first.designation}'
                          : '${requests.length} people are waiting to join',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.family,
    required this.service,
    required this.currency,
  });

  final Family family;
  final FamilyFirestoreService service;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyTransaction>>(
      stream: service.getTransactions(family.id, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final transactions = snapshot.data ?? const <FamilyTransaction>[];
        if (transactions.isEmpty) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No family transactions yet',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
            itemBuilder: (context, index) => FamilyTransactionTile(
              transaction: transactions[index],
              currency: currency,
            ),
          ),
        );
      },
    );
  }
}

class _MemberBreakdown extends StatelessWidget {
  const _MemberBreakdown({
    required this.members,
    required this.currency,
    required this.uid,
  });

  final List<FamilyMember> members;
  final String currency;
  final String uid;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...members]
      ..sort((a, b) => (b.income + b.expense).compareTo(a.income + a.expense));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            _buildRow(sorted[i]),
            if (i != sorted.length - 1)
              Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(FamilyMember member) {
    final initials = member.username.trim().isEmpty
        ? '?'
        : member.username.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE67E22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.uid == uid ? 'You' : member.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.designation,
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
                '+ $currency ${member.income.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '− $currency ${member.expense.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({
    required this.family,
    required this.service,
    required this.currency,
  });

  final Family family;
  final FamilyFirestoreService service;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilySubscription>>(
      stream: service.getSubscriptions(family.id),
      builder: (context, snapshot) {
        final subs = (snapshot.data ?? const <FamilySubscription>[])
            .where((s) => s.isActive)
            .toList();

        final monthlyTotal =
            subs.fold<double>(0, (sum, s) => sum + s.monthlyEquivalent);
        final next = subs.isEmpty ? null : subs.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.subscriptions_rounded,
                      color: Color(0xFF9B59B6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currency ${monthlyTotal.toStringAsFixed(2)} / month',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subs.isEmpty
                              ? 'No active family subscriptions'
                              : '${subs.length} active '
                                  '${subs.length == 1 ? 'subscription' : 'subscriptions'}',
                          style:
                              TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next up: ${next.name} on '
                          '${DateFormat.MMMd().format(next.nextBillingDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        '$currency ${next.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: Color(0xFF9AA3AF)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
