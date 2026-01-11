import 'dart:ui';

import 'package:finance_tracker/models/Loan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  String _selectedFilter = 'All'; // All, Given, Taken
  
  // Mock data - replace with your Firebase stream
  final List<Loan> loans = [
    Loan(
      id: '1',
      name: 'Personal Loan',
      totalAmount: 50000,
      paidAmount: 20000,
      interestRate: 12.5,
      startDate: DateTime(2024, 1, 15),
      dueDate: DateTime(2025, 1, 15),
      type: 'taken',
      lender: 'ABC Bank',
      icon: Icons.account_balance,
      color: const Color(0xFFE63946),
    ),
    Loan(
      id: '2',
      name: 'Friend Loan',
      totalAmount: 15000,
      paidAmount: 10000,
      interestRate: 0,
      startDate: DateTime(2024, 6, 1),
      dueDate: DateTime(2025, 6, 1),
      type: 'given',
      lender: 'John Doe',
      icon: Icons.person,
      color: const Color(0xFF06D6A0),
    ),
  ];

  List<Loan> get filteredLoans {
    if (_selectedFilter == 'All') return loans;
    return loans.where((loan) => 
      _selectedFilter == 'Given' ? loan.type == 'given' : loan.type == 'taken'
    ).toList();
  }

  double get totalGiven => loans
      .where((loan) => loan.type == 'given')
      .fold(0.0, (sum, loan) => sum + loan.remainingAmount);

  double get totalTaken => loans
      .where((loan) => loan.type == 'taken')
      .fold(0.0, (sum, loan) => sum + loan.remainingAmount);

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
                "Filter Loans",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('All'),
              _buildFilterOption('Given'),
              _buildFilterOption('Taken'),
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
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF1A1A1A),
                            size: 18,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Loans",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.8,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Track loans given & taken",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      GestureDetector(
                        onTap: _showFilterDialog,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedFilter != 'All' 
                                ? const Color(0xFF4A90E2) 
                                : const Color(0xFFF8F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: _selectedFilter != 'All' 
                                ? Colors.white 
                                : const Color(0xFF1A1A1A),
                            size: 20,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Add Loan page
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06D6A0).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward,
                                      size: 14,
                                      color: Color(0xFF06D6A0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Given',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs ${totalGiven.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3F3),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE63946).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward,
                                      size: 14,
                                      color: Color(0xFFE63946),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Taken',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs ${totalTaken.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),

            // Loans List
            Expanded(
              child: filteredLoans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Loans Yet",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start tracking your loans",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredLoans.length,
                      itemBuilder: (context, index) {
                        return LoanTile(loan: filteredLoans[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Loan Tile Widget
class LoanTile extends StatelessWidget {
  final Loan loan;

  const LoanTile({super.key, required this.loan});

  void _showLoanDetails(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    
    final daysRemaining = loan.dueDate.difference(DateTime.now()).inDays;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  color: loan.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: width * 0.15,
                      height: width * 0.15,
                      decoration: BoxDecoration(
                        color: loan.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        loan.icon,
                        color: loan.color,
                        size: width * 0.08,
                      ),
                    ),
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.name,
                            style: TextStyle(
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: width * 0.01),
                          Text(
                            loan.lender,
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: const Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  children: [
                    _buildDetailRow('Total Amount', 'Rs ${loan.totalAmount}', Icons.account_balance_wallet, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Paid Amount', 'Rs ${loan.paidAmount}', Icons.check_circle_outline, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Remaining', 'Rs ${loan.remainingAmount}', Icons.pending_outlined, width, 
                      valueColor: loan.type == 'given' ? const Color(0xFF06D6A0) : const Color(0xFFE63946)),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Interest Rate', '${loan.interestRate}%', Icons.percent, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Due Date', DateFormat('d MMM yyyy').format(loan.dueDate), Icons.calendar_today, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Days Remaining', daysRemaining <= 0 ? 'Overdue' : '$daysRemaining days', Icons.access_time, width,
                      valueColor: daysRemaining <= 30 ? const Color(0xFFF57C00) : const Color(0xFF06D6A0)),
                    
                    SizedBox(height: width * 0.05),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Add payment
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: width * 0.035),
                              side: const BorderSide(color: Color(0xFF06D6A0), width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payments, size: 18, color: Color(0xFF06D6A0)),
                            label: const Text('Payment', style: TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: width * 0.03),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Edit
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: width * 0.035),
                              side: const BorderSide(color: Color(0xFF4A90E2), width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4A90E2)),
                            label: const Text('Edit', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, double width, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.025),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: width * 0.045, color: const Color(0xFF666666)),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: width * 0.032, color: const Color(0xFF999999), fontWeight: FontWeight.w400)),
              SizedBox(height: width * 0.008),
              Text(value, style: TextStyle(fontSize: width * 0.04, color: valueColor ?? const Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    
    final isOverdue = loan.dueDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => _showLoanDetails(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.015),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: width * 0.12,
                  height: width * 0.12,
                  decoration: BoxDecoration(
                    color: loan.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(loan.icon, color: loan.color, size: width * 0.06),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loan.name,
                            style: TextStyle(fontSize: width * 0.042, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: loan.type == 'given' ? const Color(0xFF06D6A0).withOpacity(0.1) : const Color(0xFFE63946).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loan.type == 'given' ? 'Given' : 'Taken',
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: loan.type == 'given' ? const Color(0xFF06D6A0) : const Color(0xFFE63946),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: width * 0.01),
                      Text(
                        loan.lender,
                        style: TextStyle(fontSize: width * 0.032, color: const Color(0xFF999999), fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${loan.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: const Color(0xFF1A1A1A), fontSize: width * 0.04, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: width * 0.008),
                    Text(
                      '${loan.progressPercentage.toStringAsFixed(0)}% paid',
                      style: TextStyle(fontSize: width * 0.028, color: const Color(0xFF999999), fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: width * 0.03),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: loan.progressPercentage / 100,
                backgroundColor: const Color(0xFFF0F0F0),
                color: loan.color,
                minHeight: 6,
              ),
            ),
            if (isOverdue) ...[
              SizedBox(height: width * 0.02),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: width * 0.035, color: const Color(0xFFF57C00)),
                  SizedBox(width: width * 0.015),
                  Text(
                    'Overdue',
                    style: TextStyle(fontSize: width * 0.03, color: const Color(0xFFF57C00), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}