// Switch wizard placeholder — Phase 4C will fill this in with drug
// pickers, dose inputs, and the smart-picker tier ranking.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';

class SwitchScreen extends StatelessWidget {
  const SwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Switch wizard arrives in Phase 4C — drug pickers, dose inputs, '
            'smart-picker tier ranking.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
