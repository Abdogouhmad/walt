import 'package:flutter/material.dart';

class PageData {
  final String title, desc;
  final IconData icon;
  final Color color;

  const PageData(this.title, this.desc, this.icon, this.color);
}

class PageViewItem extends StatelessWidget {
  final PageData data;
  const PageViewItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 110, color: data.color),
          const SizedBox(height: 50),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: secondary),
          ),
        ],
      ),
    );
  }
}
