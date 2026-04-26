import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/category_icon.dart';

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

    return Slidable(
      key: Key(transaction.id.toString()),

      // Swipe Right -> Edit
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (context) {
              // TODO: Implement Edit
              debugPrint("Edit ${transaction.merchant}");
            },
            backgroundColor: context.swipeRightBackground,
            foregroundColor: Colors.white,
            icon: Icons.edit,

            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
        ],
      ),

      // Swipe Left -> Delete
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        dismissible: DismissiblePane(
          onDismissed: () {
            // TODO: Implement Delete
            debugPrint("Swiped to delete ${transaction.merchant}");
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              // TODO: Implement Delete
              debugPrint("Delete pressed for ${transaction.merchant}");
            },
            backgroundColor: context.swipeLeftBackground,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
        ],
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: context.listContainer,
          child: Icon(
            CategoryIcons.getIcon(categoryIcon),
            color: context.listIconBk,
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
      ),
    );
  }
}
