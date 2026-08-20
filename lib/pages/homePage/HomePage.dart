import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/pages/common/accountsPage/AccountSettingsPage.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/pages/familyMode/FamilyModeBody.dart';
import 'package:finance_tracker/pages/homePage/BusinessModeHomePage.dart';
import 'package:finance_tracker/pages/homePage/FamilyModeHomePage.dart';
import 'package:finance_tracker/pages/homePage/PersonalModeHomePage.dart';
import 'package:finance_tracker/pages/homePage/BusinessModeBody.dart';
import 'package:finance_tracker/pages/homePage/PersonalModeBody.dart';
import 'package:finance_tracker/service/AuthFirestoreService.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/UserFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/utilities/Globals.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserFirestoreService userService = UserFirestoreService();
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  int _currencyRefreshSignal = 0;

  @override
  void initState() {
    super.initState();

    initCurrency();

    // Initialize banner ad
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3804780729029008/8582553165',
      size: AdSize.banner,
      request: AdRequest(),
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

  Future<void> initCurrency() async {
    await CurrencyService.initializeCurrency();
  }

  Color _modeColor(AppMode mode) {
    switch (mode) {
      case AppMode.personal:
        return const Color(0xFF4A90E2);
      case AppMode.business:
        return const Color(0xFF16A085);
      case AppMode.family:
        return const Color(0xFFE67E22);
    }
  }

  IconData _modeIcon(AppMode mode) {
    switch (mode) {
      case AppMode.personal:
        return Icons.person_outline_rounded;
      case AppMode.business:
        return Icons.business_center_outlined;
      case AppMode.family:
        return Icons.family_restroom_outlined;
    }
  }

  Future<void> _showModeSelector() async {
    final selectedMode = await showModalBottomSheet<AppMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Switch mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose a workspace profile for this session.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...Globals.selectableModes.map(
                    (mode) {
                      final isSelected = mode == Globals.currentMode;
                      final color = _modeColor(mode);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(sheetContext, mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.10)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withOpacity(0.55)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.16)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      _modeIcon(mode),
                                      color: color,
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mode.label,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mode == AppMode.personal
                                              ? 'Everyday money tracking'
                                              : mode == AppMode.business
                                                  ? 'Business income and expenses'
                                                  : 'Shared household finances',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? color
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedMode == null || selectedMode == Globals.currentMode) return;

    await Globals.setMode(selectedMode);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildModeToggleButton() {
    final modeColor = _modeColor(Globals.currentMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showModeSelector,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: modeColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: modeColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_modeIcon(Globals.currentMode), color: modeColor, size: 16),
              const SizedBox(width: 6),
              Text(
                Globals.currentMode.label,
                style: TextStyle(
                  color: modeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: modeColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddTransaction() async {
    final isOnline = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a transaction',
    );
    if (!isOnline) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Transaction saved successfully.'),
          ),
        );
    }
  }

  PreferredSizeWidget _buildHomeAppBar(Map<String, dynamic> data) {
    return StandardAppBar(
      title: "Hello ${data["username"]} !",
      useCustomDesign: true,
      leading: Globals.currentMode == AppMode.personal
          ? Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1A1A1A),
                    size: 22,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      actions: [
        // Nothing to switch to when family mode is compiled out.
        if (Globals.familyModeEnabled) _buildModeToggleButton(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsPage(),
              ),
            ).then((_) async {
              await initCurrency();
              if (!mounted) return;
              setState(() {
                _currencyRefreshSignal++;
              });
            });
          },
          icon: const Icon(Icons.person, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currUser = FirebaseAuth.instance.currentUser;

    // If user is not logged in, return empty container
    if (currUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: StreamBuilder(
        stream: userService.getUserDataByEmail(currUser.email!),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Scaffold(
              backgroundColor: const Color(0xfff8f8fa),
              body: Center(
                child: LottieBuilder.asset("assets/lottiejson/loading.json"),
              ),
            );
          }

          final data = snapshot.data![0];

          // Initialize currency symbol in SharedPreferences if not already set
          final preferredCurrency =
              data["preferredCurrency"]?.toString() ?? 'NPR';
          CurrencyService.setCurrencyFromCode(preferredCurrency);

          final appBar = _buildHomeAppBar(data);

          if (Globals.currentMode == AppMode.business) {
            return BusinessModeHomePage(
              appBar: appBar,
              body: BusinessModeBody(data: data),
            );
          }

          // The `familyModeEnabled` const lets the compiler drop this branch —
          // and with it the whole family feature — from a release build.
          if (Globals.familyModeEnabled &&
              Globals.currentMode == AppMode.family) {
            return FamilyModeHomePage(
              appBar: appBar,
              body: FamilyModeBody(data: data),
            );
          }

          return PersonalModeHomePage(
            appBar: appBar,
            body: PersonalModeBody(
              data: data,
              currUser: currUser,
              bannerAd: _bannerAd,
              isBannerAdLoaded: _isBannerAdLoaded,
              onAccountSettingsReturn: initCurrency,
              currencyRefreshSignal: _currencyRefreshSignal,
            ),
          );
        },
      ),
    );
  }
}
