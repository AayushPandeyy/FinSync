import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/pages/homePage/EditTransactionPage.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/TransactionTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SeeAllTransactionsPage extends StatefulWidget {
  const SeeAllTransactionsPage({super.key});

  @override
  State<SeeAllTransactionsPage> createState() => _SeeAllTransactionsPageState();
}

class _SeeAllTransactionsPageState extends State<SeeAllTransactionsPage> {
  String _selectedFilter = 'All Time';
  String _selectedCategory = 'All Categories';
  String _currencySymbol = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  DateTime _parseMonthYear(String monthYear) {
    List<String> parts = monthYear.split(' ');
    int month = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ].indexOf(parts[0]) +
        1;
    int year = int.parse(parts[1]);
    return DateTime(year, month);
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    DateTime now = DateTime.now();
    List<dynamic> filtered = transactions;

    // Filter by time period
    if (_selectedFilter == 'This Month') {
      filtered = filtered.where((transaction) {
        DateTime date = transaction["date"].toDate();
        return date.year == now.year && date.month == now.month;
      }).toList();
    } else if (_selectedFilter == 'Last Month') {
      DateTime lastMonth = DateTime(now.year, now.month - 1);
      filtered = filtered.where((transaction) {
        DateTime date = transaction["date"].toDate();
        return date.year == lastMonth.year && date.month == lastMonth.month;
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All Categories') {
      filtered = filtered.where((transaction) {
        return transaction["category"] == _selectedCategory;
      }).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(28),
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
                        "Filter Transactions",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Period Section
                      Text(
                        "TIME PERIOD",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFilterOption('This Month', setModalState),
                      _buildFilterOption('Last Month', setModalState),
                      _buildFilterOption('All Time', setModalState),

                      const SizedBox(height: 24),

                      // Category Section
                      Text(
                        "CATEGORY",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Get all unique categories
                      StreamBuilder(
                        stream: TransactionFirestoreService()
                            .getTransactionsOfUser(
                                FirebaseAuth.instance.currentUser!.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final allCategories = <String>{'All Categories'};
                            for (var transaction in snapshot.data!) {
                              allCategories
                                  .add(transaction["category"] as String);
                            }

                            return Column(
                              children: [
                                _buildCategoryOption(
                                    'All Categories', setModalState),
                                ...allCategories
                                    .where((cat) => cat != 'All Categories')
                                    .map((category) => _buildCategoryOption(
                                        category, setModalState))
                                    .toList(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Reset and Apply buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'All Time';
                                  _selectedCategory = 'All Categories';
                                });
                                setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF000000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String filter, StateSetter setModalState) {
    bool isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        setModalState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF000000) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF000000)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF000000) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              filter,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String category, StateSetter setModalState) {
    bool isSelected = _selectedCategory == category;

    // Get category icon
    IconData categoryIcon = Icons.category;
    if (category != 'All Categories') {
      final categoryData = Categories().categories.firstWhere(
          (cat) => cat.name == category,
          orElse: () => Categories().categories.first);
      categoryIcon = categoryData.icon;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        setModalState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF000000) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF000000)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF000000) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              categoryIcon,
              size: 18,
              color: isSelected ? const Color(0xFF000000) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button, Filter button, and Add button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF000000),
                            size: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showFilterDialog,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (_selectedFilter != 'All Time' ||
                                        _selectedCategory != 'All Categories')
                                    ? const Color(0xFF000000)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.filter_list,
                                color: (_selectedFilter != 'All Time' ||
                                        _selectedCategory != 'All Categories')
                                    ? Colors.white
                                    : const Color(0xFF000000),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final isOnline =
                                  await ConnectivityService.ensureConnected(
                                context,
                                actionDescription: 'add a transaction',
                              );
                              if (!isOnline) return;

                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddTransactionPage(),
                                ),
                              );

                              if (result == true && mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Transaction saved successfully.'),
                                    ),
                                  );
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    "Transactions",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: Color(0xFF000000),
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),

                  // Active filters indicator
                  if (_selectedFilter != 'All Time' ||
                      _selectedCategory != 'All Categories') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_selectedFilter != 'All Time')
                          _buildActiveFilterChip(_selectedFilter),
                        if (_selectedCategory != 'All Categories')
                          _buildActiveFilterChip(_selectedCategory),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),

            // Transactions list
            Expanded(
              child: StreamBuilder(
                  stream: TransactionFirestoreService().getTransactionsOfUser(
                      FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF000000),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final data = snapshot.data;

                    // Apply filters
                    final filteredData = _filterTransactions(data!);

                    if (filteredData.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No transactions found",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Try adjusting your filters",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group transactions by month
                    Map<String, List<dynamic>> groupedTransactions = {};
                    for (var transaction in filteredData) {
                      DateTime date = transaction["date"].toDate();
                      String monthYear =
                          "${_getMonthName(date.month)} ${date.year}";

                      if (!groupedTransactions.containsKey(monthYear)) {
                        groupedTransactions[monthYear] = [];
                      }
                      groupedTransactions[monthYear]!.add(transaction);
                    }

                    // Sort months in descending order
                    var sortedMonths = groupedTransactions.keys.toList()
                      ..sort((a, b) {
                        DateTime dateA = _parseMonthYear(a);
                        DateTime dateB = _parseMonthYear(b);
                        return dateB.compareTo(dateA);
                      });

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: sortedMonths.length,
                      itemBuilder: (context, monthIndex) {
                        String month = sortedMonths[monthIndex];
                        List<dynamic> transactions =
                            groupedTransactions[month]!;

                        // Sort transactions within month by date (newest first)
                        transactions.sort((a, b) {
                          DateTime dateA = a["date"].toDate();
                          DateTime dateB = b["date"].toDate();
                          return dateB.compareTo(dateA);
                        });

                        // Calculate totals for the month
                        double totalIncome = 0;
                        double totalExpense = 0;

                        for (var transaction in transactions) {
                          double amount =
                              (transaction["amount"] as num).toDouble();
                          if (transaction["type"] == "INCOME") {
                            totalIncome += amount;
                          } else {
                            totalExpense += amount;
                          }
                        }

                        double totalAmount = totalIncome - totalExpense;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month header
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 20, 24, 12),
                              child: Text(
                                month,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Transactions for this month
                            ...transactions.map((transaction) {
                              return GestureDetector(
                                onTap: () {
                                  IconData categoryIcon = Categories()
                                      .categories
                                      .firstWhere(
                                          (cat) =>
                                              cat.name ==
                                              transaction["category"],
                                          orElse: () =>
                                              Categories().categories.first)
                                      .icon;
                                  DialogBox().showTransactionDetailPopUp(
                                      context,
                                      TransactionModel(
                                        id: transaction["id"],
                                        title: transaction["title"],
                                        amount: (transaction["amount"] as num)
                                            .toDouble(),
                                        date: transaction["date"].toDate(),
                                        transactionDescription:
                                            transaction["description"],
                                        category: transaction["category"],
                                        type: transaction["type"],
                                      ),
                                      categoryIcon);
                                },
                                child: Slidable(
                                  endActionPane: ActionPane(
                                      extentRatio: 0.5,
                                      motion: const ScrollMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditTransactionPage(
                                                            id: transaction[
                                                                "id"],
                                                            type: transaction[
                                                                "type"],
                                                            title: transaction[
                                                                "title"],
                                                            description: transaction[
                                                                "description"],
                                                            amount: (transaction[
                                                                        "amount"]
                                                                    as num)
                                                                .toDouble(),
                                                            category:
                                                                transaction[
                                                                    "category"],
                                                            date: transaction[
                                                                    "date"]
                                                                .toDate())));
                                          },
                                          backgroundColor:
                                              const Color(0xFF000000),
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Edit',
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(0),
                                            bottomLeft: Radius.circular(0),
                                          ),
                                        ),
                                        SlidableAction(
                                          onPressed: (context) async {
                                            await TransactionFirestoreService()
                                                .deleteTransaction(
                                                    FirebaseAuth.instance
                                                        .currentUser!.uid,
                                                    transaction["id"],
                                                    (transaction["amount"]
                                                            as num)
                                                        .toDouble(),
                                                    transaction["type"]);
                                          },
                                          backgroundColor:
                                              const Color(0xFFE63946),
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                        ),
                                      ]),
                                  child: TransactionTile(
                                      title: transaction["title"],
                                      date: transaction["date"].toDate(),
                                      amount: (transaction["amount"] as num)
                                          .toDouble(),
                                      type: transaction["type"],
                                      category: transaction["category"]),
                                ),
                              );
                            }).toList(),

                            // Month summary
                            Container(
                              margin: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF06D6A0),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Income",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF666666),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "$_currencySymbol ${totalIncome.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF06D6A0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE63946),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Expense",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF666666),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "$_currencySymbol ${totalExpense.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE63946),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(
                                      color: Color(0xFFE0E0E0),
                                      height: 1,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "$_currencySymbol ${totalAmount.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: totalAmount >= 0
                                              ? const Color(0xFF06D6A0)
                                              : const Color(0xFFE63946),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                if (label == _selectedFilter) {
                  _selectedFilter = 'All Time';
                } else {
                  _selectedCategory = 'All Categories';
                }
              });
            },
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
