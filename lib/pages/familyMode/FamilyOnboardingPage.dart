import 'package:finance_tracker/enums/family/FamilyRole.dart';
import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown in family mode when the signed-in user is not in a family yet.
/// Offers the two ways in: start a new family, or ask to join one by code.
class FamilyOnboardingPage extends StatefulWidget {
  const FamilyOnboardingPage({
    super.key,
    required this.username,
    required this.email,
  });

  final String username;
  final String email;

  @override
  State<FamilyOnboardingPage> createState() => _FamilyOnboardingPageState();
}

class _FamilyOnboardingPageState extends State<FamilyOnboardingPage> {
  static const Color _accent = Color(0xFFE67E22);

  final FamilyFirestoreService _service = FamilyFirestoreService();

  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final _familyNameController = TextEditingController();
  final _codeController = TextEditingController();

  String _createDesignation = 'Father';
  String _joinDesignation = 'Son';

  bool _busy = false;
  int _tab = 0;

  List<FamilyJoinRequest> _pendingRequests = const [];
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final requests = await _service.getMyPendingRequests(uid);
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _loadingRequests = false;
      });
    } catch (_) {
      // A missing collection-group index only costs us the banner, not the page.
      if (!mounted) return;
      setState(() => _loadingRequests = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createFamily() async {
    if (!await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'create a family',
    )) {
      return;
    }
    if (!(_createFormKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final family = await _service.createFamily(
        creatorUid: user.uid,
        creatorName: widget.username,
        creatorEmail: widget.email,
        familyName: _familyNameController.text.trim(),
        designation: _createDesignation,
      );

      if (!mounted) return;
      setState(() => _busy = false);

      await DialogBox().showMessageDialog(
        context,
        isSuccess: true,
        title: 'Family created',
        message:
            '${family.name} is ready. Share the code ${family.code} with the '
            'people you want to invite — you approve each request.',
      );
    } on FamilyException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Could not create the family. Please try again.');
    }
  }

  Future<void> _requestToJoin() async {
    if (!await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'join a family',
    )) {
      return;
    }
    if (!(_joinFormKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final family = await _service.requestToJoin(
        code: _codeController.text.trim(),
        uid: user.uid,
        username: widget.username,
        email: widget.email,
        designation: _joinDesignation,
      );

      if (!mounted) return;
      setState(() => _busy = false);
      _codeController.clear();
      await _loadPendingRequests();

      if (!mounted) return;
      await DialogBox().showMessageDialog(
        context,
        isSuccess: true,
        title: 'Request sent',
        message:
            'An admin of ${family.name} needs to approve you. You will see the '
            'family dashboard as soon as they do.',
      );
    } on FamilyException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Could not send the request. Please try again.');
    }
  }

  Future<void> _cancelRequest(FamilyJoinRequest request) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (request.familyId.isEmpty) return;

    try {
      await _service.cancelMyRequest(familyId: request.familyId, uid: uid);
      await _loadPendingRequests();
      if (!mounted) return;
      _showSnack('Request withdrawn.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not withdraw the request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          if (!_loadingRequests && _pendingRequests.isNotEmpty) ...[
            ..._pendingRequests.map(_buildPendingBanner),
            const SizedBox(height: 6),
          ],
          _buildTabSwitcher(),
          const SizedBox(height: 16),
          if (_tab == 0) _buildCreateCard() else _buildJoinCard(),
          const SizedBox(height: 18),
          _buildHowItWorks(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'One pot, everyone in it',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Family mode keeps its own income, expenses and subscriptions — '
            'separate from your personal books. Every member adds entries and '
            'they all roll up into one shared balance.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner(FamilyJoinRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiting for approval',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You asked to join as ${request.designation}.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _cancelRequest(request),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF0F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Create a family', Icons.add_home_rounded),
          _buildTabButton(1, 'Join with code', Icons.vpn_key_rounded),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? _accent : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? _accent : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCard() {
    return _CardShell(
      child: Form(
        key: _createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Family name'),
            TextFormField(
              controller: _familyNameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'e.g. The Sharma Family',
                icon: Icons.home_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Give your family a name';
                }
                if (value.trim().length < 3) {
                  return 'Use at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Your designation'),
            _DesignationPicker(
              value: _createDesignation,
              onChanged: (value) => setState(() => _createDesignation = value),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: 'Create family',
              icon: Icons.add_home_rounded,
              busy: _busy,
              onPressed: _createFamily,
            ),
            const SizedBox(height: 10),
            const Text(
              'You become the first admin and get a 6-character invite code.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCard() {
    return _CardShell(
      child: Form(
        key: _joinFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Family code'),
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
              decoration: _inputDecoration(
                hint: 'ABC123',
                icon: Icons.vpn_key_rounded,
              ).copyWith(counterText: ''),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the code an admin shared with you';
                }
                if (value.trim().length < 6) {
                  return 'Codes are at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Your designation'),
            _DesignationPicker(
              value: _joinDesignation,
              onChanged: (value) => setState(() => _joinDesignation = value),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: 'Request to join',
              icon: Icons.send_rounded,
              busy: _busy,
              onPressed: _requestToJoin,
            ),
            const SizedBox(height: 10),
            const Text(
              'An admin reviews every request before you can see family data.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    const steps = [
      (
        Icons.groups_rounded,
        'Everyone contributes',
        'Each member books family income and expenses from their own phone.',
      ),
      (
        Icons.summarize_rounded,
        'Totals combine',
        'The dashboard shows the whole family pot plus a per-member breakdown.',
      ),
      (
        Icons.lock_outline_rounded,
        'Personal stays personal',
        'Nothing from your personal mode is visible to the family, and vice versa.',
      ),
    ];

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How family mode works',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          for (final step in steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(step.$1, color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.$3,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (step != steps.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF9AA3AF)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
    ),
  );
}

/// Family codes are stored uppercase; normalise as the user types so the
/// lookup always matches.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

/// Chips for the common relationships, with an "Other" escape hatch that opens
/// a free-text field — designations are not a fixed vocabulary.
class _DesignationPicker extends StatefulWidget {
  const _DesignationPicker({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_DesignationPicker> createState() => _DesignationPickerState();
}

class _DesignationPickerState extends State<_DesignationPicker> {
  late final TextEditingController _customController =
      TextEditingController(text: _isPreset(widget.value) ? '' : widget.value);

  bool _custom = false;

  @override
  void initState() {
    super.initState();
    _custom = !_isPreset(widget.value);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  static bool _isPreset(String value) =>
      kFamilyDesignations.where((d) => d != 'Other').contains(value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: kFamilyDesignations.map((designation) {
            final isOther = designation == 'Other';
            final selected =
                isOther ? _custom : (!_custom && widget.value == designation);

            return ChoiceChip(
              label: Text(designation),
              selected: selected,
              onSelected: (_) {
                setState(() => _custom = isOther);
                if (isOther) {
                  widget.onChanged(
                    _customController.text.trim().isEmpty
                        ? 'Member'
                        : _customController.text.trim(),
                  );
                } else {
                  widget.onChanged(designation);
                }
              },
              selectedColor: const Color(0xFFE67E22),
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
              backgroundColor: const Color(0xFFF3F4F6),
              side: BorderSide.none,
            );
          }).toList(),
        ),
        if (_custom) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _customController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'e.g. Uncle, Elder Son',
              icon: Icons.badge_outlined,
            ),
            onChanged: (value) => widget.onChanged(
              value.trim().isEmpty ? 'Member' : value.trim(),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE67E22),
          disabledBackgroundColor: const Color(0xFFE67E22).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 20),
        label: Text(
          busy ? 'Please wait…' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
