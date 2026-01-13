import 'package:finance_tracker/service/IOUFirestoreService.dart';
import 'package:finance_tracker/widgets/IOUPage/IOUTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/pages/IOUpage/AddIOUPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IOUPage extends StatefulWidget {
  const IOUPage({super.key});

  @override
  State<IOUPage> createState() => _IOUPageState();
}

class _IOUPageState extends State<IOUPage> {
  String _selectedFilter = 'All';

  String uid = FirebaseAuth.instance.currentUser!.uid;
  final Ioufirestoreservice firestoreService = Ioufirestoreservice();

  List<IOU> _applyFilter(List<IOU> ious) {
    List<IOU> filtered;

    switch (_selectedFilter) {
      case 'I Owe':
        filtered = ious.where((i) => i.iouType == IOUType.OWE).toList();
        break;
      case 'Owed to Me':
        filtered = ious.where((i) => i.iouType == IOUType.OWED).toList();
        break;
      default:
        filtered = ious;
    }

    filtered.sort((a, b) {
      if (a.status != b.status) {
        return a.status == IOUStatus.PENDING ? -1 : 1;
      }
      return b.date.compareTo(a.date);
    });

    return filtered;
  }

  double _totalIOwe(List<IOU> ious) {
    return ious
        .where((i) => i.iouType == IOUType.OWE && i.status == IOUStatus.PENDING)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double _totalOwedToMe(List<IOU> ious) {
    return ious
        .where(
            (i) => i.iouType == IOUType.OWED && i.status == IOUStatus.PENDING)
        .fold(0.0, (sum, i) => sum + i.amount);
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
            color:
                isSelected ? const Color(0xFF4A90E2) : const Color(0xFFE5E5E5),
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
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
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
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        FirebaseAuth.instance.currentUser!.uid; // Replace with real UID

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Nav Bar ---
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
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "I Owe You & You Owe Me",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w400,
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddIOUPage()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // --- Summary Cards ---
                  StreamBuilder<List<IOU>>(
                    stream: firestoreService.getIOUsStream(userId),
                    builder: (context, snapshot) {
                      final allIOUs = snapshot.data ?? [];
                      final totalIOwe = _totalIOwe(allIOUs);
                      final totalOwedToMe = _totalOwedToMe(allIOUs);

                      return Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              title: 'I Owe',
                              amount: totalIOwe,
                              icon: Icons.arrow_downward,
                              color: const Color(0xFFE63946),
                              bgColor: const Color(0xFFFFF3F3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              title: 'Owed to Me',
                              amount: totalOwedToMe,
                              icon: Icons.arrow_upward,
                              color: const Color(0xFF06D6A0),
                              bgColor: const Color(0xFFF0F7FF),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFFF0F0F0)),

            // --- IOUs List ---
            Expanded(
              child: StreamBuilder<List<IOU>>(
                stream: firestoreService.getIOUsStream(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  }

                  final allIOUs = snapshot.data ?? [];
                  final filteredIOUs = _applyFilter(allIOUs);

                  if (filteredIOUs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("No IOUs Yet",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredIOUs.length,
                    itemBuilder: (context, index) {
                      return IOUTile(
                        iou: filteredIOUs[index],
                        onDelete: () async {
                          await firestoreService.deleteIOU(
                              uid, filteredIOUs[index].id);
                        },
                        onEdit: () {},
                        onSettle: () async {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Summary card ---
  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Rs ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
