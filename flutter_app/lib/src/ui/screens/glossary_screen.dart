// Glossary screen — searchable list of clinical terms.
//
// Static, searchable list of clinical terms. Pure presentation over
// listGlossary() / lookupTerm() — no Riverpod / no engine state.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
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
    final all = listGlossary();
    final entries = _filtered();
    final hasQuery = _searchCtl.text.trim().isNotEmpty;
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
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.xs,
              ),
              child: TextField(
                controller: _searchCtl,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search QTc, EPS, MAOI, FBC…',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Results meta — count + clear-all hint.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    hasQuery
                        ? '${entries.length} of ${all.length} match'
                            '${entries.length == 1 ? '' : 'es'}'
                        : '${all.length} term${all.length == 1 ? '' : 's'}',
                    style: AppTextSizes.micro,
                  ),
                ],
              ),
            ),
            if (entries.isEmpty)
              const Expanded(child: _GlossaryEmpty())
            else if (context.isWide)
              // Wide: 2-column tile grid via GridView for proper
              // wrapping at long-content rows.
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.xs,
                    AppSpace.lg,
                    AppSpace.xl,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 480,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _GlossaryTile(entry: entries[i]),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.xs,
                    AppSpace.lg,
                    AppSpace.xl,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Gap.v(AppSpace.sm),
                  itemBuilder: (_, i) => _GlossaryTile(entry: entries[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryEmpty extends StatelessWidget {
  const _GlossaryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.muted,
              size: 24,
            ),
          ),
          const Gap.v(AppSpace.md),
          const Text('No matching terms', style: AppTextSizes.subtitle),
          const Gap.v(AppSpace.xs),
          Text(
            'Try a shorter query or another acronym.',
            style: AppTextSizes.caption.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
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
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md + 2,
      ),
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
          const Gap.v(AppSpace.xs + 2),
          Text(
            entry.definition,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (entry.relevance != null) ...<Widget>[
            const Gap.v(AppSpace.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border(
                  left: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.sm + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.warning.withValues(alpha: 0.9),
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: Text(
                      entry.relevance!,
                      style: TextStyle(
                        color: AppColors.warning.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
