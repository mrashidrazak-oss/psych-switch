// Glossary screen — Phase 7A.
//
// Static, searchable list of clinical terms. Pure presentation over
// listGlossary() / lookupTerm() — no Riverpod / no engine state.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/glossary.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<GlossaryEntry> _filtered() {
    final all = listGlossary();
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (e) =>
              e.term.toLowerCase().contains(q) ||
              e.definition.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glossary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtl,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search QTc, EPS, MAOI, FBC…',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (entries.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No matching terms.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _GlossaryTile(entry: entries[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryTile extends StatelessWidget {
  const _GlossaryTile({required this.entry});

  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            entry.term.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.definition,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (entry.relevance != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                border: Border(
                  left: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Text(
                entry.relevance!,
                style: TextStyle(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
