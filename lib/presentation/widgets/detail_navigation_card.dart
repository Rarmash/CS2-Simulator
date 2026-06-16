import 'package:flutter/material.dart';

class DetailNavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DetailNavigationAction> actions;

  const DetailNavigationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  OutlinedButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailNavigationAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const DetailNavigationAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}
