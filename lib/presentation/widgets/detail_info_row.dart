import 'package:flutter/material.dart';

class DetailInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final double titleWidth;

  const DetailInfoRow({
    super.key,
    required this.title,
    required this.value,
    this.titleWidth = 118,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: titleWidth,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
