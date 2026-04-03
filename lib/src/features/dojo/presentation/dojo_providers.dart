import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import '../data/dojo_repository.dart';
import '../domain/dojo_stats.dart';

final dojoStatsProvider = FutureProvider<DojoStats>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return DojoRepository(isar: isar).fetchStats();
});