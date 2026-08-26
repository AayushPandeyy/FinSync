import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Who is opening the dialog, which decides what confirming actually does.
enum SettleMode {
  /// A payee asking the payer to approve money they have sent back.
  request,

  /// The payer recording money they have already received in person.
  record,
}

/// Collects a settlement amount and files it against a split bill.
///
/// In [SettleMode.request] this creates a PENDING request the payer must
/// approve. In [SettleMode.record] the payer is the approver, so the money
/// moves immediately.
class SettleSplitDialog extends StatefulWidget {
  final SplitBill bill;

  /// The payee whose balance this settlement is against. In request mode this
  /// is the current user; in record mode it is whoever the payer picked.
  final String payeeUid;

  /// The signed-in user performing the action.
  final String actorUid;

  final SettleMode mode;

  const SettleSplitDialog({
    super.key,
    required this.bill,
    required this.payeeUid,
    required this.actorUid,
    this.mode = SettleMode.request,
  });

  @override
  State<SettleSplitDialog> createState() => _SettleSplitDialogState();
}

class _SettleSplitDialogState extends State<SettleSplitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final SplitBillsFirestoreService _service = SplitBillsFirestoreService();

  String _currencySymbol = 'Rs';
  bool _isSubmitting = false;
  String? _submitError;

  static const _green = Color(0xFF06D6A0);
  static const _ink = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF999999);
  static const _label = Color(0xFF666666);
  static const _red = Color(0xFFE63946);
  static const _border = Color(0xFFE5E5E5);

  bool get _isRequest => widget.mode == SettleMode.request;

  /// The most that may go into this settlement. A payee cannot stack a second
  /// request on top of one already awaiting approval; a payer recording a
  /// payment is limited only by what is still outstanding.
  double get _maxAmount => _isRequest
      ? widget.bill.settleableFor(widget.payeeUid)
      : widget.bill.remainingFor(widget.payeeUid);

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    // Settling in full is the common case — offer it pre-filled.
    _amountController.text = _maxAmount.toStringAsFixed(2);
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) setState(() => _currencySymbol = symbol);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _money(double value) =>
      '$_currencySymbol ${value.toStringAsFixed(2)}';

  void _setAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {});
  }

  String? _validateAmount(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return 'Enter an amount';

    final amount = double.tryParse(text);
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > _maxAmount + kMoneyEpsilon) {
      return 'Maximum is ${_money(_maxAmount)}';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription:
          _isRequest ? 'send a settlement request' : 'record a settlement',
    );
    if (!canProceed) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    try {
      if (_isRequest) {
        await _service.requestSettlement(
          bill: widget.bill,
          fromUid: widget.payeeUid,
          amount: amount,
          note: note,
        );
      } else {
        await _service.recordSettlementAsPayer(
          bill: widget.bill,
          payeeUid: widget.payeeUid,
          amount: amount,
          payerUid: widget.actorUid,
          note: note,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on SettlementException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = _isRequest
            ? 'Could not send the request. Please try again.'
            : 'Could not record the settlement. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bill = widget.bill;
    final share = bill.shareOf(widget.payeeUid);
    final settled = bill.settledOf(widget.payeeUid);
    final pending = bill.pendingFor(widget.payeeUid);
    final counterpartName = _isRequest
        ? bill.nameOf(bill.paidBy, fallback: 'the payer')
        : bill.nameOf(widget.payeeUid, fallback: 'this person');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(counterpartName),
                SizedBox(height: width * 0.05),
                _balanceCard(share: share, settled: settled, pending: pending),
                SizedBox(height: width * 0.05),
                if (_maxAmount > 0) ...[
                  _quickSelect(),
                  SizedBox(height: width * 0.05),
                ],
                _amountField(),
                const SizedBox(height: 16),
                _noteField(),
                if (_isRequest) ...[
                  const SizedBox(height: 16),
                  _approvalNotice(counterpartName),
                ],
                if (_submitError != null) ...[
                  const SizedBox(height: 14),
                  _errorBanner(_submitError!),
                ],
                SizedBox(height: width * 0.06),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pieces ────────────────────────────────────────────────────────────────

  Widget _header(String counterpartName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.payments_outlined, color: _green, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRequest ? 'Settle up' : 'Record payment',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isRequest
                    ? 'Pay back $counterpartName'
                    : 'Received from $counterpartName',
                style: const TextStyle(fontSize: 14, color: _muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _balanceCard({
    required double share,
    required double settled,
    required double pending,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _balanceRow(_isRequest ? 'Your share' : 'Their share', share),
          const SizedBox(height: 8),
          _balanceRow('Already settled', settled),
          if (pending > 0) ...[
            const SizedBox(height: 8),
            _balanceRow('Awaiting approval', pending, color: _pendingColor),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: _border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRequest ? 'You can settle' : 'Still outstanding',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              Text(
                _money(_maxAmount),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _pendingColor = Color(0xFFF39C12);

  Widget _balanceRow(String label, double amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: color ?? _label)),
        Text(
          _money(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? _ink,
          ),
        ),
      ],
    );
  }

  Widget _quickSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick select',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _label,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickButton('25%', _maxAmount * 0.25),
            const SizedBox(width: 8),
            _quickButton('50%', _maxAmount * 0.50),
            const SizedBox(width: 8),
            _quickButton('75%', _maxAmount * 0.75),
            const SizedBox(width: 8),
            _quickButton('Full', _maxAmount),
          ],
        ),
      ],
    );
  }

  Widget _quickButton(String label, double amount) {
    final rounded = double.parse(amount.toStringAsFixed(2));
    final isActive =
        double.tryParse(_amountController.text.trim()) == rounded;

    return Expanded(
      child: InkWell(
        onTap: _isSubmitting ? null : () => _setAmount(rounded),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _green.withOpacity(0.12) : Colors.white,
            border: Border.all(color: isActive ? _green : _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? _green : _label,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _label,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() {}),
          validator: _validateAmount,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            prefixText: '$_currencySymbol  ',
            prefixStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
            hintText: '0.00',
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _label,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          enabled: !_isSubmitting,
          maxLength: 120,
          style: const TextStyle(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            hintText: _isRequest ? 'Sent via eSewa' : 'Paid in cash',
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _approvalNotice(String payerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pendingColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pendingColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: _pendingColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$payerName has to approve this before your balance changes.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF8A6114),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: _red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: Color(0xFF9B2F28)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _border),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _label,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: _green.withOpacity(0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isRequest ? 'Send for approval' : 'Record payment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
