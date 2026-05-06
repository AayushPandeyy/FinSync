import 'dart:async';

import 'package:finance_tracker/models/Wallet.dart';
import 'package:finance_tracker/service/WalletFirestoreService.dart';
import 'package:finance_tracker/service/TransferFirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage>
    with SingleTickerProviderStateMixin {
  final WalletFirestoreService _walletService = WalletFirestoreService();
  final TransferFirestoreService _transferService = TransferFirestoreService();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  late final AnimationController _swapController;
  StreamSubscription? _walletSubscription;

  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  List<WalletModel> _wallets = [];
  bool _isLoading = false;

  // ── palette ──────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _ink = Color(0xFF0D1117);
  static const _muted = Color(0xFF8A94A6);
  static const _border = Color(0xFFE4E8F0);
  static const _accent = Color(0xFF2563EB);
  static const _accentSoft = Color(0xFFEFF4FF);

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _loadWallets();
  }

  void _loadWallets() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _walletSubscription = _walletService.getWalletsOfUser(uid).listen((list) {
      if (mounted) {
        setState(() {
          _wallets = WalletModel.listFromJson(list);
          if (_fromWallet == null && _wallets.isNotEmpty) {
            _fromWallet = _wallets[0];
          }
          if (_toWallet == null && _wallets.length > 1) {
            _toWallet = _wallets[1];
          }
        });
      }
    });
  }

  void _swapWallets() {
    HapticFeedback.lightImpact();
    _swapController.forward(from: 0);
    setState(() {
      final tmp = _fromWallet;
      _fromWallet = _toWallet;
      _toWallet = tmp;
    });
  }

  Future<void> _selectWallet(bool isFrom) async {
    final selected = await showModalBottomSheet<WalletModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _WalletPickerSheet(
        wallets: _wallets,
        excludeId: isFrom ? _toWallet?.id : _fromWallet?.id,
        label: isFrom ? 'From wallet' : 'To wallet',
      ),
    );
    if (selected == null) return;
    setState(() {
      if (isFrom) {
        _fromWallet = selected;
      } else {
        _toWallet = selected;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_fromWallet == null || _toWallet == null) {
      _showError('Please select both wallets.');
      return;
    }
    if (_fromWallet!.id == _toWallet!.id) {
      _showError('Source and destination must be different.');
      return;
    }
    if (_fromWallet!.balance < amt) {
      _showError('Insufficient balance in source wallet.');
      return;
    }

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _transferService.transferBetweenWallets(
        uid: uid,
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amt,
        note: null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF16A34A),
          content: const Text(
            'Transfer completed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFDC2626),
        content: Text(
          msg,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _amountController.dispose();
    _amountFocus.dispose();
    _swapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _ink, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Transfer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Amount hero ────────────────────────────────────────────
              _AmountCard(
                controller: _amountController,
                focusNode: _amountFocus,
              ),
              const SizedBox(height: 24),

              // ── Wallet selector ────────────────────────────────────────
              _SectionLabel(label: 'Wallets'),
              const SizedBox(height: 10),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      _WalletSelector(
                        role: 'From',
                        wallet: _fromWallet,
                        roleColor: const Color(0xFF2563EB),
                        roleBg: const Color(0xFFEFF4FF),
                        onTap: () => _selectWallet(true),
                      ),
                      const SizedBox(height: 2),
                      _ConnectorLine(),
                      const SizedBox(height: 2),
                      _WalletSelector(
                        role: 'To',
                        wallet: _toWallet,
                        roleColor: const Color(0xFF16A34A),
                        roleBg: const Color(0xFFDCFCE7),
                        onTap: () => _selectWallet(false),
                      ),
                    ],
                  ),

                  // Swap button centered on the divider
                  // Positioned(
                  //   top: 100,
                  //   right: 16,
                  //   child: _SwapButton(
                  //     controller: _swapController,
                  //     onTap: _swapWallets,
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Transfer summary ───────────────────────────────────────
              if (_fromWallet != null && _toWallet != null) ...[
                _SectionLabel(label: 'Summary'),
                const SizedBox(height: 10),
                _SummaryCard(
                  fromWallet: _fromWallet!,
                  toWallet: _toWallet!,
                  amount: double.tryParse(_amountController.text),
                ),
                const SizedBox(height: 28),
              ],

              // ── CTA ────────────────────────────────────────────────────
              _TransferButton(onPressed: _submit, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount card ──────────────────────────────────────────────────────────────

class _AmountCard extends StatefulWidget {
  const _AmountCard({required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_AmountCard> createState() => _AmountCardState();
}

class _AmountCardState extends State<_AmountCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.focusNode.hasFocus
                ? const Color(0xFF2563EB).withOpacity(0.4)
                : const Color(0xFFE4E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount to transfer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A94A6),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NPR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1117),
                      letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1117).withOpacity(0.15),
                        letterSpacing: -1,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      setState(() {});
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFF8A94A6)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wallet selector tile ─────────────────────────────────────────────────────

class _WalletSelector extends StatelessWidget {
  const _WalletSelector({
    required this.role,
    required this.wallet,
    required this.roleColor,
    required this.roleBg,
    required this.onTap,
  });

  final String role;
  final WalletModel? wallet;
  final Color roleColor;
  final Color roleBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: roleColor.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: roleColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      wallet?.name ?? 'Select wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: wallet != null
                            ? const Color(0xFF0D1117)
                            : const Color(0xFF8A94A6),
                      ),
                    ),
                    if (wallet != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Balance: ${wallet!.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A94A6)),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Connector line between wallets ───────────────────────────────────────────

class _ConnectorLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 37),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            width: 2,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Swap button ──────────────────────────────────────────────────────────────

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.controller, required this.onTap});
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) => Transform.rotate(
          angle: controller.value * 3.14159,
          child: child,
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.swap_vert_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.fromWallet,
    required this.toWallet,
    required this.amount,
  });

  final WalletModel fromWallet;
  final WalletModel toWallet;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    final remaining = amount != null
        ? (fromWallet.balance - amount!).toStringAsFixed(2)
        : '-';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'From',
            value: fromWallet.name,
            valueStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1117)),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'To',
            value: toWallet.name,
            valueStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1117)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFD1DCF5)),
          ),
          _SummaryRow(
            label: 'Remaining balance',
            value: remaining,
            valueStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: (amount != null && fromWallet.balance - amount! < 0)
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueStyle,
  });
  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6))),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A94A6),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Transfer CTA ──────────────────────────────────────────────────────────────

class _TransferButton extends StatelessWidget {
  const _TransferButton({required this.onPressed, required this.isLoading});
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Transfer Funds',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Wallet picker bottom sheet ────────────────────────────────────────────────

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({
    required this.wallets,
    required this.excludeId,
    required this.label,
  });

  final List<WalletModel> wallets;
  final String? excludeId;
  final String label;

  @override
  Widget build(BuildContext context) {
    final available = wallets.where((w) => w.id != excludeId).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1117),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No wallets available',
                  style: TextStyle(color: Color(0xFF8A94A6)),
                ),
              ),
            )
          else
            ...available.map((w) => _WalletPickerTile(
                  wallet: w,
                  onTap: () => Navigator.pop(context, w),
                )),
        ],
      ),
    );
  }
}

class _WalletPickerTile extends StatelessWidget {
  const _WalletPickerTile({required this.wallet, required this.onTap});
  final WalletModel wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1117),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Balance: ${wallet.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
