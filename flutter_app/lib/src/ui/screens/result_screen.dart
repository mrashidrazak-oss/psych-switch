// Result screen placeholder — Phase 4D fills in the schedule table,
// safety flags, citations, monitoring plan and PsychSwitch Score ring.
//
// The args type is exported so the router can carry the wizard's
// SwitchInput across the navigation transition without resorting to a
// global state holder.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/engine/switching_engine.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Payload passed via `GoRouterState.extra` when navigating to /result.
class ResultScreenArgs {
  const ResultScreenArgs({required this.input});

  final SwitchInput input;
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, this.args});

  final ResultScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Result screen arrives in Phase 4D — schedule table, '
                'safety flags, citations, monitoring plan.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (args != null) ...<Widget>[
                const SizedBox(height: 24),
                Text(
                  '${args!.input.fromDrugId} ${args!.input.fromDoseMg} mg → '
                  '${args!.input.toDrugId} ${args!.input.toDoseMg} mg',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
