import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/core/constants/app_colors.dart'; // For your extensions
import 'package:walt/core/utils/category_icon.dart'; // For CategoryIcons.getIcon

class TxList extends StatelessWidget {
  final WaltTransaction transaction;
  final String categoryName;
  final String categoryIcon;

  const TxList({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type.toLowerCase() == 'income';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: context.listContainer, // From your extension
        child: Icon(
          CategoryIcons.getIcon(categoryIcon), 
          color: context.listIconBk, // From your extension
        ),
      ),
      title: Text(
        transaction.merchant ?? 'Unknown Merchant',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$categoryName • ${DateFormat('HH:mm').format(transaction.date)}',
        style: TextStyle(color: context.listSubLabel, fontSize: 12),
      ),
      trailing: Text(
        "${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} MAD",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome ? context.listIncome : context.listExpense,
        ),
      ),
    );
  }
}