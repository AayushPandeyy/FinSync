import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/models/TransactionTemplate.dart';
import 'package:finance_tracker/models/Wallet.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/service/WalletFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Bottom sheet used to create a transaction from a [TransactionTemplate].
/// Only the amount (and, optionally, the wallet) needs to be entered — the
/// title, description and category come from the template, and the date is
/// always today.
///
/// Pops with `true` if a transaction was saved.
class QuickAddTemplateSheet extends StatefulWidget {
  final TransactionTemplate template;

  const QuickAddTemplateSheet({super.key, required this.template});

  @override
  State<QuickAddTemplateSheet> createState() => _QuickAddTemplateSheetState();
}

class _QuickAddTemplateSheetState extends State<QuickAddTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final WalletFirestoreService _walletService = WalletFirestoreService();
  final TransactionFirestoreService _transactionService =
      TransactionFirestoreService();

  List<WalletModel> _wallets = [];
  String _selectedWalletName = '';
  bool _walletsLoading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _walletService.ensureWalletsExist(uid);
    _walletService.getWalletsOfUser(uid).listen((data) {
      if (!mounted) return;
      final wallets = data.map((json) => WalletModel.fromJson(json)).toList();
      setState(() {
        _wallets = wallets;
        _walletsLoading = false;
        if (_selectedWalletName.isEmpty && wallets.isNotEmpty) {
          _selectedWalletName = wallets.first.name;
        }
      });
    });
  }

  Future<void> _save() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a transaction',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount.');
      return;
    }
    if (parsedAmount > 99999999) {
      setState(() => _errorMessage = 'Amount too large');
      return;
    }

    final roundedAmount = double.parse(parsedAmount.toStringAsFixed(2));
    final template = widget.template;

    final transaction = TransactionModel(
      id: const Uuid().v1(),
      title: template.title,
      amount: roundedAmount,
      date: DateTime.now(),
      transactionDescription: template.description,
      category: template.category,
      type: template.type,
      wallet: _selectedWalletName,
    );

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _transactionService.addTransaction(
        FirebaseAuth.instance.currentUser!.uid,
        transaction,
      );

      if (!mounted) return;
      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = e.message ?? 'Failed to add transaction.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Failed to add transaction. Please try again.';
      });
    }
  }

  IconData _walletIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'digital':
        return Icons.phone_android;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final isExpense = template.type == 'EXPENSE';
    final accentColor = isExpense ? Colors.red : Colors.green;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpense
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${template.category} • ${DateFormat.yMMMMd().format(DateTime.now())}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (template.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 20),
                const Text("Amount",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (parsed > 99999999) {
                      return 'Amount too large';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text("Wallet",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _walletsLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _wallets.map((wallet) {
                          final isSelected =
                              _selectedWalletName == wallet.name;
                          return ChoiceChip(
                            avatar: Icon(
                              _walletIcon(wallet.type),
                              size: 16,
                              color: isSelected ? Colors.white : accentColor,
                            ),
                            label: Text(wallet.name),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedWalletName = wallet.name),
                            selectedColor: accentColor,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? accentColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            "Add Transaction",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
