import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/proof_entry.dart';
import '../../data/repositories/proof_repository.dart';
import '../../domain/proof_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final proofRepositoryProvider = Provider<ProofRepository>((ref) {
  return ProofRepository(Hive.box<ProofEntry>(AppConstants.proofEntriesBox));
});

/// All proof entries, newest first.
final allProofProvider =
    StateNotifierProvider<ProofController, List<ProofEntry>>(
  (ref) => ProofController(ref),
);

/// Proof entries for a specific habit.
final habitProofProvider = Provider.family<List<ProofEntry>, String>(
  (ref, habitId) => ref
      .watch(allProofProvider)
      .where((e) => e.habitId == habitId)
      .toList(),
);

/// Whether a habit is completed today.
/// Watches [allProofProvider] so it rebuilds whenever proof is added/removed.
final isCompletedTodayProvider = Provider.family<bool, String>(
  (ref, habitId) {
    final entries = ref.watch(habitProofProvider(habitId));
    final today = DateTime.now();
    return entries.any(
      (e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), today),
    );
  },
);

/// Proof for a habit on a specific date.
/// Watches [allProofProvider] so it rebuilds whenever proof is added/removed.
final proofOnDateProvider =
    Provider.family<ProofEntry?, ({String habitId, DateTime date})>(
  (ref, args) {
    final entries = ref.watch(habitProofProvider(args.habitId));
    return entries
        .where(
          (e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), args.date),
        )
        .firstOrNull;
  },
);

// ── Controller ─────────────────────────────────────────────────────────────

class ProofController extends StateNotifier<List<ProofEntry>> {
  final Ref _ref;

  ProofController(this._ref) : super([]) {
    _load();
    _listenForChanges();
  }

  ProofRepository get _repo => _ref.read(proofRepositoryProvider);

  void _load() {
    state = _repo.getAll();
  }

  void _listenForChanges() {
    _repo.watch().listen((_) => _load());
  }

  Future<ProofEntry> addProof({
    required String sourcePath,
    required String habitId,
    String? note,
  }) async {
    final entry = await ProofService.createEntry(
      sourcePath: sourcePath,
      habitId: habitId,
      note: note,
    );
    await _repo.save(entry);
    _load();
    return entry;
  }

  Future<void> deleteEntry(ProofEntry entry) async {
    await ProofService.deleteEntry(entry);
    await _repo.delete(entry.id);
    _load();
  }

  Future<void> deleteAllForHabit(String habitId) async {
    final entries = _repo.getForHabit(habitId);
    for (final e in entries) {
      await ProofService.deleteEntry(e);
    }
    await _repo.deleteAllForHabit(habitId);
    _load();
  }
}
