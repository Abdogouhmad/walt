import 'package:flutter/material.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/core/constants/app_colors.dart';

class HeaderList extends StatelessWidget {
  final String date;
  const HeaderList({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UiText(
          text: date.toUpperCase(),
          type: UiTextType.labelLarge,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.listTitle,
          ),
        ),
        // UiText(
        //   text: "Total +1000 MAD",
        //   type: UiTextType.labelSmall,
        //   style: TextStyle(
        //     color: context.listSubLabel,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }
}
