import 'package:flutter/material.dart';

class OpeningLoadingCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const OpeningLoadingCard({
    super.key,
    required this.title,
    this.subtitle = 'Please wait',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}