import 'package:finance_tracker/models/Wallet.dart';
import 'package:finance_tracker/service/WalletFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyFormatter.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class WalletsPage extends StatefulWidget {
  const WalletsPage({super.key});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  final WalletFirestoreService _walletService = WalletFirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _initialized = false;
  Map<String, Map<String, double>> _walletStats = {};

  @override
  void initState() {
    super.initState();
    _ensureWallets();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3804780729029008/8582553165',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  Future<void> _ensureWallets() async {
    await _walletService.ensureWalletsExist(_uid);
    // Listen to wallet stats
    _walletService.getWalletStats(_uid).listen((stats) {
      if (mounted) {
        setState(() {
          _walletStats = stats;
        });
      }
    });
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  IconData _getWalletIcon(String type) {
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

  Color _getWalletColor(String type) {
    switch (type) {
      case 'cash':
        return const Color(0xFF27AE60);
      case 'bank':
        return const Color(0xFF2980B9);
      case 'digital':
        return const Color(0xFF8E44AD);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  String _getWalletDescription(String type) {
    switch (type) {
      case 'cash':
        return 'Physical cash on hand';
      case 'bank':
        return 'Bank account balance';
      case 'digital':
        return 'E-wallets & digital payments';
      default:
        return 'Custom wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Wallets',
        subtitle: 'Manage your wallets',
        useCustomDesign: true,
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _walletService.getWalletsOfUser(_uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final wallets = snapshot.data!
                    .map((json) => WalletModel.fromJson(json))
                    .toList();

                if (wallets.isEmpty) {
                  return const Center(
                    child: Text('No wallets found.'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add custom wallet button
                      _buildAddWalletButton(),

                      const SizedBox(height: 24),

                      // Section title
                      Text(
                        "Your Wallets",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Wallet cards
                      ...wallets.map((wallet) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onLongPress: () =>
                                  _showWalletOptionsSheet(wallet),
                              child: _buildWalletCard(wallet),
                            ),
                          )),

                      const SizedBox(height: 16),

                      // Info card
                      _buildInfoCard(),

                      const SizedBox(height: 16),

                      if (_isBannerAdLoaded)
                        Center(
                          child: SizedBox(
                            width: _bannerAd.size.width.toDouble(),
                            height: _bannerAd.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAddWalletButton() {
    return GestureDetector(
      onTap: () => _showAddWalletDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF4A90E2),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Custom Wallet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create a new wallet to track your funds',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFBBBBBB),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog() {
    final nameController = TextEditingController();
    String selectedType = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const Text(
                        'Add Custom Wallet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a new wallet to organize your finances',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Wallet name field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Wallet Name',
                          hintText: 'e.g. Savings, Crypto, PayPal',
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4A90E2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF999999)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Wallet type selector
                      const Text(
                        'Wallet Type',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTypeChip(
                            label: 'Cash',
                            type: 'cash',
                            icon: Icons.money,
                            selected: selectedType == 'cash',
                            onTap: () {
                              setModalState(() => selectedType = 'cash');
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildTypeChip(
                            label: 'Bank',
                            type: 'bank',
                            icon: Icons.account_balance,
                            selected: selectedType == 'bank',
                            onTap: () {
                              setModalState(() => selectedType = 'bank');
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildTypeChip(
                            label: 'Digital',
                            type: 'digital',
                            icon: Icons.phone_android,
                            selected: selectedType == 'digital',
                            onTap: () {
                              setModalState(() => selectedType = 'digital');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Add button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a wallet name.'),
                                ),
                              );
                              return;
                            }

                            final newWallet = WalletModel(
                              id: 'wallet_${DateTime.now().millisecondsSinceEpoch}_$_uid',
                              name: name,
                              icon: selectedType,
                              balance: 0.0,
                              type: selectedType,
                              userId: _uid,
                            );

                            await _walletService.addWallet(_uid, newWallet);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Wallet "$name" added successfully.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String type,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = _getWalletColor(type);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey[400], size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(WalletModel wallet) {
    final color = _getWalletColor(wallet.type);
    final icon = _getWalletIcon(wallet.type);
    final stats = _walletStats[wallet.name] ?? {'income': 0.0, 'expense': 0.0};
    final income = stats['income'] ?? 0.0;
    final expense = stats['expense'] ?? 0.0;
    final balance = income - expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon, name, type badge
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  wallet.type[0].toUpperCase() + wallet.type.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Balance
          Text(
            CurrencyFormatter.formatAmountSync(balance),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.grey[100],
          ),

          const SizedBox(height: 14),

          // Income & Expense row
          Row(
            children: [
              // Income
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Color(0xFF27AE60),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatAmountSync(income),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 36,
                color: Colors.grey[200],
              ),

              // Expense
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatAmountSync(expense),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFFE74C3C),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFE082),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wallet balances update automatically when you add transactions. Long press a wallet to edit or delete it.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber[900],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletOptionsSheet(WalletModel wallet) {
    final color = _getWalletColor(wallet.type);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Wallet name header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getWalletIcon(wallet.type),
                          color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage wallet options',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Edit option
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Wallet',
                  subtitle: 'Change name or type',
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditWalletDialog(wallet);
                  },
                ),

                const SizedBox(height: 10),

                // Delete option
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete Wallet',
                  subtitle: 'Remove this wallet permanently',
                  color: const Color(0xFFE74C3C),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteWallet(wallet);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }

  void _showEditWalletDialog(WalletModel wallet) {
    final nameController = TextEditingController(text: wallet.name);
    String selectedType = wallet.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const Text(
                        'Edit Wallet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your wallet details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Wallet name field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Wallet Name',
                          hintText: 'e.g. Savings, Crypto, PayPal',
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4A90E2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF999999)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Wallet type selector
                      const Text(
                        'Wallet Type',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTypeChip(
                            label: 'Cash',
                            type: 'cash',
                            icon: Icons.money,
                            selected: selectedType == 'cash',
                            onTap: () {
                              setModalState(() => selectedType = 'cash');
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildTypeChip(
                            label: 'Bank',
                            type: 'bank',
                            icon: Icons.account_balance,
                            selected: selectedType == 'bank',
                            onTap: () {
                              setModalState(() => selectedType = 'bank');
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildTypeChip(
                            label: 'Digital',
                            type: 'digital',
                            icon: Icons.phone_android,
                            selected: selectedType == 'digital',
                            onTap: () {
                              setModalState(() => selectedType = 'digital');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a wallet name.'),
                                ),
                              );
                              return;
                            }

                            final updatedWallet = wallet.copyWith(
                              name: name,
                              type: selectedType,
                              icon: selectedType,
                            );

                            await _walletService.updateWallet(
                                _uid, updatedWallet,
                                oldName: wallet.name);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Wallet "$name" updated successfully.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteWallet(WalletModel wallet) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Delete Wallet',
      message:
          'Are you sure you want to delete "${wallet.name}"? This action cannot be undone. Transactions linked to this wallet will not be deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirmed) {
      await _walletService.deleteWallet(_uid, wallet.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Wallet "${wallet.name}" deleted.'),
            ),
          );
      }
    }
  }
}
