import 'dart:ui';

import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/pages/IOUpage/AddIOUPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IOUPage extends StatefulWidget {
  const IOUPage({super.key});

  @override
  State<IOUPage> createState() => _IOUPageState();
}

class _IOUPageState extends State<IOUPage> {
  String _selectedFilter = 'All'; // All, I Owe, Owed to Me
  
  // Mock data - replace with your Firebase stream
  final List<IOU> ious = [
    IOU(
      id: '1',
      personName: 'Sarah Johnson',
      amount: 2500,
      description: 'Dinner split last weekend',
      date: DateTime(2024, 12, 15),
      dueDate: DateTime(2025, 1, 15),
      iouType: IOUType.OWE,
      status: IOUStatus.PENDING,

    ),
    IOU(
      id: '2',
      personName: 'Mike Chen',
      amount: 5000,
      description: 'Borrowed for emergency',
      date: DateTime(2024, 11, 20),
      dueDate: DateTime(2025, 2, 1),
      iouType: IOUType.OWE,
      status: IOUStatus.PENDING,

    ),
    IOU(
      id: '3',
      personName: 'Emma Wilson',
      amount: 1200,
      description: 'Movie tickets and snacks',
      date: DateTime(2024, 12, 28),
      iouType: IOUType.OWE,
      status: IOUStatus.SETTLED,

    ),
  ];

  List<IOU> get filteredIOUs {
    List<IOU> filtered;
    if (_selectedFilter == 'All') {
      filtered = ious;
    } else if (_selectedFilter == 'I Owe') {
      filtered = ious.where((iou) => iou.iouType == IOUType.OWE).toList();
    } else {
      filtered = ious.where((iou) => iou.iouType == IOUType.OWE).toList();
    }
    
    // Sort: pending first, then by date
    filtered.sort((a, b) {
      if (a.status != b.status) {
        return a.status == 'pending' ? -1 : 1;
      }
      return b.date.compareTo(a.date);
    });
    
    return filtered;
  }

  double get totalIOwe => ious
      .where((iou) => iou.iouType == IOUType.OWE && iou.status == 'pending')
      .fold(0.0, (sum, iou) => sum + iou.amount);

  double get totalOwedToMe => ious
      .where((iou) => iou.iouType == IOUType.OWE && iou.status == 'pending')
      .fold(0.0, (sum, iou) => sum + iou.amount);

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
                "Filter IOUs",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('All'),
              _buildFilterOption('I Owe'),
              _buildFilterOption('Owed to Me'),
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
                              "IOUs",
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
                              "I Owe You & You Owe Me",
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
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> AddIOUPage()));
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
                                    'I Owe',
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
                                'Rs ${totalIOwe.toStringAsFixed(0)}',
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
                                    'Owed to Me',
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
                                'Rs ${totalOwedToMe.toStringAsFixed(0)}',
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

            // IOUs List
            Expanded(
              child: filteredIOUs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No IOUs Yet",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start tracking what you owe",
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
                      itemCount: filteredIOUs.length,
                      itemBuilder: (context, index) {
                        return IOUTile(iou: filteredIOUs[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// IOU Tile Widget
class IOUTile extends StatelessWidget {
  final IOU iou;

  const IOUTile({super.key, required this.iou});

  void _showIOUDetails(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    
    final daysRemaining = iou.dueDate != null 
        ? iou.dueDate!.difference(DateTime.now()).inDays 
        : null;
    
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
                  color: iou.status == 'settled' 
                      ? const Color(0xFFF0F0F0) 
                      : (iou.iouType == IOUType.OWE
                          ? const Color(0xFFFFF3F3) 
                          : const Color(0xFFF0F7FF)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            iou.personName,
                            style: TextStyle(
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: width * 0.01),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iou.iouType == IOUType.OWE 
                                  ? const Color(0xFFE63946).withOpacity(0.15) 
                                  : const Color(0xFF06D6A0).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              iou.iouType == IOUType.OWE ? 'I Owe' : 'Owes Me',
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: iou.iouType == 'owe' 
                                    ? const Color(0xFFE63946) 
                                    : const Color(0xFF06D6A0),
                                fontWeight: FontWeight.w600,
                              ),
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
                    _buildDetailRow('Amount', 'Rs ${iou.amount}', Icons.payments_outlined, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Description', iou.description, Icons.description_outlined, width),
                    SizedBox(height: width * 0.04),
                    _buildDetailRow('Date', DateFormat('d MMM yyyy').format(iou.date), Icons.calendar_today, width),
                    if (iou.dueDate != null) ...[
                      SizedBox(height: width * 0.04),
                      _buildDetailRow('Due Date', DateFormat('d MMM yyyy').format(iou.dueDate!), Icons.event, width),
                      SizedBox(height: width * 0.04),
                      _buildDetailRow(
                        'Days Remaining', 
                        daysRemaining! <= 0 ? 'Overdue' : '$daysRemaining days', 
                        Icons.access_time, 
                        width,
                        valueColor: daysRemaining <= 7 ? const Color(0xFFF57C00) : const Color(0xFF06D6A0)
                      ),
                    ],
                    SizedBox(height: width * 0.04),
                    _buildDetailRow(
                      'Status', 
                      iou.status == 'settled' ? 'Settled' : 'Pending', 
                      iou.status == 'settled' ? Icons.check_circle : Icons.pending, 
                      width,
                      valueColor: iou.status == 'settled' ? const Color(0xFF06D6A0) : const Color(0xFFF57C00)
                    ),
                    
                    SizedBox(height: width * 0.05),
                    
                    if (iou.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Mark as settled
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: width * 0.035),
                                backgroundColor: const Color(0xFF06D6A0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                              label: const Text('Settle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Send reminder
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: width * 0.035),
                                side: const BorderSide(color: Color(0xFF4A90E2), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.notifications, size: 18, color: Color(0xFF4A90E2)),
                              label: const Text('Remind', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Delete
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: width * 0.035),
                          side: const BorderSide(color: Color(0xFFE63946), width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE63946)),
                        label: const Text('Delete', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w600)),
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
    
    final isOverdue = iou.dueDate != null && iou.dueDate!.isBefore(DateTime.now());
    final isSettled = iou.status == 'settled';

    return GestureDetector(
      onTap: () => _showIOUDetails(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.015),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSettled ? const Color(0xFFE5E5E5) : (isOverdue ? const Color(0xFFF57C00).withOpacity(0.3) : const Color(0xFFE5E5E5)), 
            width: 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              iou.personName,
                              style: TextStyle(
                                fontSize: width * 0.042, 
                                fontWeight: FontWeight.w600, 
                                color: const Color(0xFF1A1A1A),
                                decoration: isSettled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isSettled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06D6A0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Settled',
                                style: TextStyle(
                                  fontSize: width * 0.028,
                                  color: const Color(0xFF06D6A0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: width * 0.01),
                      Text(
                        iou.description,
                        style: TextStyle(fontSize: width * 0.032, color: const Color(0xFF999999), fontWeight: FontWeight.w400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${iou.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: iou.iouType == IOUType.OWE ? const Color(0xFFE63946) : const Color(0xFF06D6A0), 
                        fontSize: width * 0.042, 
                        fontWeight: FontWeight.w600,
                        decoration: isSettled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: width * 0.008),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: iou.iouType == IOUType.OWE 
                            ? const Color(0xFFE63946).withOpacity(0.1) 
                            : const Color(0xFF06D6A0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        iou.iouType == IOUType.OWE ? 'I Owe' : 'Owes Me',
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: iou.iouType == IOUType.OWE ? const Color(0xFFE63946) : const Color(0xFF06D6A0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (iou.dueDate != null && !isSettled) ...[
              SizedBox(height: width * 0.02),
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_amber : Icons.calendar_today, 
                    size: width * 0.03, 
                    color: isOverdue ? const Color(0xFFF57C00) : const Color(0xFF999999)
                  ),
                  SizedBox(width: width * 0.015),
                  Text(
                    isOverdue ? 'Overdue' : 'Due ${DateFormat("d MMM yyyy").format(iou.dueDate!)}',
                    style: TextStyle(
                      fontSize: width * 0.03, 
                      color: isOverdue ? const Color(0xFFF57C00) : const Color(0xFF999999), 
                      fontWeight: FontWeight.w400
                    ),
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