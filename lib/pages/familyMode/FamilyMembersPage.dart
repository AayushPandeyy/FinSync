import 'package:finance_tracker/enums/family/FamilyRole.dart';
import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Roster + invite code. Admins additionally get the approval queue and the
/// promote / change-designation / remove controls.
class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key, required this.family});

  final Family family;

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  static const Color _accent = Color(0xFFE67E22);

  final FamilyFirestoreService _service = FamilyFirestoreService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Family Members',
        subtitle: widget.family.name,
        useCustomDesign: true,
      ),
      body: SafeArea(
        top: false,
        // The family doc is re-streamed so admin changes (a promotion, a new
        // code) take effect on this screen without a pop-and-reopen.
        child: StreamBuilder<Family?>(
          stream: _service.getFamily(widget.family.id),
          initialData: widget.family,
          builder: (context, familySnapshot) {
            final family = familySnapshot.data;
            if (family == null) {
              return const Center(
                child: Text('This family no longer exists.'),
              );
            }

            final isAdmin = family.isAdmin(_uid);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                _buildCodeCard(family, isAdmin),
                const SizedBox(height: 20),
                if (isAdmin) ...[
                  _buildRequestsSection(family),
                  const SizedBox(height: 20),
                ],
                _buildMembersSection(family, isAdmin),
                const SizedBox(height: 24),
                _buildLeaveButton(family),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodeCard(Family family, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Invite code',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  family.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 7,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: family.code));
                  if (!mounted) return;
                  _showSnack('Code ${family.code} copied.');
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Share this with people you want in the family. You approve '
                    'every request before they see any data.'
                : 'Anyone with this code can request to join. An admin has to '
                    'approve them.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _regenerateCode(family),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                label: const Text(
                  'Generate a new code',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _regenerateCode(Family family) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'New invite code',
      message: 'The current code stops working immediately. Anyone you already '
          'shared it with will need the new one.',
      confirmText: 'Generate',
    );
    if (!confirmed) return;

    try {
      final code = await _service.regenerateCode(family.id);
      if (!mounted) return;
      _showSnack('New code: $code');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not generate a new code.');
    }
  }

  Widget _buildRequestsSection(Family family) {
    return StreamBuilder<List<FamilyJoinRequest>>(
      stream: _service.getPendingRequests(family.id),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <FamilyJoinRequest>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionTitle('Join requests'),
                if (requests.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: const Center(
                  child: Text(
                    'Nobody is waiting to join.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF9AA3AF)),
                  ),
                ),
              )
            else
              ...requests.map((request) => _buildRequestCard(family, request)),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(Family family, FamilyJoinRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(name: request.username),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.designation} • ${request.email}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectRequest(family, request),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRequest(family, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(
    Family family,
    FamilyJoinRequest request,
  ) async {
    try {
      await _service.approveRequest(familyId: family.id, request: request);
      if (!mounted) return;
      _showSnack('${request.username} joined as ${request.designation}.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not approve that request.');
    }
  }

  Future<void> _rejectRequest(
    Family family,
    FamilyJoinRequest request,
  ) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Decline request',
      message: '${request.username} will not be added to the family. They can '
          'request again with the code.',
      confirmText: 'Decline',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await _service.rejectRequest(familyId: family.id, uid: request.uid);
      if (!mounted) return;
      _showSnack('Request declined.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not decline that request.');
    }
  }

  Widget _buildMembersSection(Family family, bool isAdmin) {
    final currency = CurrencyService.getCurrencySymbolSync();

    return StreamBuilder<List<FamilyMember>>(
      stream: _service.getMembers(family.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = [...(snapshot.data ?? const <FamilyMember>[])]
          ..sort((a, b) {
            if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
            return a.username.compareTo(b.username);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Members (${members.length})'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    _buildMemberRow(
                      family: family,
                      member: members[i],
                      isAdmin: isAdmin,
                      currency: currency,
                    ),
                    if (i != members.length - 1)
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberRow({
    required Family family,
    required FamilyMember member,
    required bool isAdmin,
    required String currency,
  }) {
    final isSelf = member.uid == _uid;
    // Admins manage everyone but themselves; you always manage your own label.
    final canManage = isAdmin && !isSelf;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          _Avatar(name: member.username),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isSelf ? '${member.username} (you)' : member.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
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
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${member.designation} • joined '
                  '${DateFormat.yMMMd().format(member.joinedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  'Contributed $currency ${member.income.toStringAsFixed(0)} • '
                  'spent $currency ${member.expense.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9AA3AF),
                  ),
                ),
              ],
            ),
          ),
          if (canManage || isSelf)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF9AA3AF)),
              onSelected: (value) =>
                  _handleMemberAction(value, family, member),
              itemBuilder: (context) => [
                if (canManage || isSelf)
                  const PopupMenuItem(
                    value: 'designation',
                    child: Text('Change designation'),
                  ),
                if (canManage)
                  PopupMenuItem(
                    value: 'role',
                    child: Text(
                      member.isAdmin ? 'Demote to member' : 'Make admin',
                    ),
                  ),
                if (canManage)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove from family',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleMemberAction(
    String action,
    Family family,
    FamilyMember member,
  ) async {
    switch (action) {
      case 'designation':
        await _changeDesignation(family, member);
        break;
      case 'role':
        await _toggleRole(family, member);
        break;
      case 'remove':
        await _removeMember(family, member);
        break;
    }
  }

  Future<void> _changeDesignation(Family family, FamilyMember member) async {
    final controller = TextEditingController(text: member.designation);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change designation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Father, Elder Son',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null || result.isEmpty) return;

    try {
      await _service.updateDesignation(
        familyId: family.id,
        uid: member.uid,
        designation: result,
      );
      if (!mounted) return;
      _showSnack('Designation updated.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not update the designation.');
    }
  }

  Future<void> _toggleRole(Family family, FamilyMember member) async {
    final makeAdmin = !member.isAdmin;

    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: makeAdmin ? 'Make admin' : 'Demote to member',
      message: makeAdmin
          ? '${member.username} will be able to approve new members, change '
              'roles and rotate the invite code.'
          : '${member.username} will keep adding family entries but lose '
              'member management.',
      confirmText: makeAdmin ? 'Make admin' : 'Demote',
      isDangerous: !makeAdmin,
    );
    if (!confirmed) return;

    try {
      await _service.setRole(
        familyId: family.id,
        uid: member.uid,
        role: makeAdmin ? FamilyRole.admin : FamilyRole.member,
      );
      if (!mounted) return;
      _showSnack(makeAdmin
          ? '${member.username} is now an admin.'
          : '${member.username} is now a member.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not change that role.');
    }
  }

  Future<void> _removeMember(Family family, FamilyMember member) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Remove member',
      message: '${member.username} loses access to family data. Entries they '
          'already added stay in the shared ledger.',
      confirmText: 'Remove',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await _service.removeMember(familyId: family.id, uid: member.uid);
      if (!mounted) return;
      _showSnack('${member.username} was removed.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not remove that member.');
    }
  }

  Widget _buildLeaveButton(Family family) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _leaveFamily(family),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFFECACA)),
          backgroundColor: const Color(0xFFFEF2F2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Leave this family',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _leaveFamily(Family family) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Leave ${family.name}',
      message: 'You will stop seeing family data. You can rejoin later with '
          'the invite code, subject to admin approval.',
      confirmText: 'Leave',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await _service.leaveFamily(familyId: family.id, uid: _uid);
      if (!mounted) return;
      Navigator.pop(context);
    } on FamilyException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not leave the family.');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22).withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE67E22),
        ),
      ),
    );
  }
}
