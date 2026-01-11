import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:flutter/material.dart';

class IOU {
  final String id;
  final String personName;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime? dueDate;
  final IOUType iouType; // 'owe' (you owe someone) or 'owed' (someone owes you)
  final IOUStatus status; // 'pending', 'settled'


  IOU({
    required this.id,
    required this.personName,
    required this.amount,
    required this.description,
    required this.date,
    this.dueDate,
    required this.iouType,
    this.status = IOUStatus.PENDING,

  });
}