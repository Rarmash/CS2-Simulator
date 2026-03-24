import 'package:flutter/material.dart';

import '../../data/repositories/local_data_repository.dart';
import 'case_list_screen.dart';
import 'tradeup_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocalDataRepository repository;

  const HomeScreen({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS2 Simulator'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _menuButton(
                  context,
                  title: '🎰 Open Cases',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseListScreen(repository: repository),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _menuButton(
                  context,
                  title: '🔄 Trade-Up',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradeUpScreen(repository: repository),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      BuildContext context, {
        required String title,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}