import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/pages/homePage/EditTransactionPage.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
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
  String _selectedFilter = 'All Time'; // Default filter

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  DateTime _parseMonthYear(String monthYear) {
    List<String> parts = monthYear.split(' ');
    int month = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ].indexOf(parts[0]) + 1;
    int year = int.parse(parts[1]);
    return DateTime(year, month);
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    DateTime now = DateTime.now();
    
    if (_selectedFilter == 'This Month') {
      return transactions.where((transaction) {
        DateTime date = transaction["date"].toDate();
        return date.year == now.year && date.month == now.month;
      }).toList();
    } else if (_selectedFilter == 'Last Month') {
      DateTime lastMonth = DateTime(now.year, now.month - 1);
      return transactions.where((transaction) {
        DateTime date = transaction["date"].toDate();
        return date.year == lastMonth.year && date.month == lastMonth.month;
      }).toList();
    }
    
    return transactions; // All Time
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Transactions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('This Month'),
              _buildFilterOption('Last Month'),
              _buildFilterOption('All Time'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    bool isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : const Color(0xFFF8F8FA),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFFE5E5E5),
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
                  color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              filter,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
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
                                color: _selectedFilter != 'All Time'
                                    ? const Color(0xFF000000)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.filter_list,
                                color: _selectedFilter != 'All Time'
                                    ? Colors.white
                                    : const Color(0xFF000000),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddTransactionPage(),
                                ),
                              );
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
                stream: FirestoreService()
                    .getTransactionsOfUser(FirebaseAuth.instance.currentUser!.uid),
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
                  
                  // Apply filter
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
                            "No transactions",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap + to add your first one",
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
                    String monthYear = "${_getMonthName(date.month)} ${date.year}";
                    
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
                      List<dynamic> transactions = groupedTransactions[month]!;
                      
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
                        double amount = (transaction["amount"] as num).toDouble();
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
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
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
                                        (cat) => cat['name'] == transaction["category"],
                                        orElse: () => {'icon': Icons.help_outline})['icon'];
                                DialogBox().showTransactionDetailPopUp(
                                    context,
                                    TransactionModel(
                                      id: transaction["id"],
                                      title: transaction["title"],
                                      amount: (transaction["amount"] as num).toDouble(),
                                      date: transaction["date"].toDate(),
                                      transactionDescription: transaction["description"],
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
                                                          id: transaction["id"],
                                                          type: transaction["type"],
                                                          title: transaction["title"],
                                                          description:
                                                              transaction["description"],
                                                          amount: (transaction["amount"] as num).toDouble(),
                                                          category:
                                                              transaction["category"],
                                                          date: transaction["date"]
                                                              .toDate())));
                                        },
                                        backgroundColor: const Color(0xFF000000),
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
                                          await FirestoreService()
                                              .deleteTransaction(
                                                  FirebaseAuth
                                                      .instance.currentUser!.uid,
                                                  transaction["id"],
                                                  (transaction["amount"] as num).toDouble(),
                                                  transaction["type"]);
                                        },
                                        backgroundColor: const Color(0xFFE63946),
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                      ),
                                    ]),
                                child: TransactionTile(
                                      title: 
                                        transaction["title"],
                                        date: 
                                        transaction["date"].toDate(),
                                        amount: 
                                        (transaction["amount"] as num).toDouble(),
                                        type: 
                                        transaction["type"],
                                        category: 
                                        transaction["category"]),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      "Rs ${totalIncome.toStringAsFixed(0)}",
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      "Rs ${totalExpense.toStringAsFixed(0)}",
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      "Rs ${totalAmount.toStringAsFixed(0)}",
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
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}