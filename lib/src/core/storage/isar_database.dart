import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/lessons/data/models/kana_card.dart';
import '../../features/lessons/data/seed/kana_seed_service.dart';

class IsarDatabase {
  const IsarDatabase._();

  static const _dbName = 'kana_quest';

  static Isar? _instance;
  static Future<Isar>? _initializing;

  /// Initialize the Isar database singleton. Must be called once on app startup.
  static Future<Isar> initialize() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    // Ensure all concurrent callers await the same Isar.open call.
    if (_initializing != null) {
      return _initializing!;
    }

    _initializing = _initializeInternal();

    try {
      final isar = await _initializing!;
      await KanaSeedService.ensureSeeded(isar);
      _instance = isar;
      return isar;
    } finally {
      _initializing = null;
    }
  }

  static Future<Isar> _initializeInternal() async {
    final directoryPath = kIsWeb
        ? ''
        : (await getApplicationDocumentsDirectory()).path;

    try {
      final opened = await Isar.open(
        [KanaCardSchema],
        directory: directoryPath,
        name: _dbName,
      );
      return opened;
    } catch (error) {
      final message = error.toString().toLowerCase();

      // Hot restart/dev cycles may already have an open named instance.
      if (message.contains('already been opened')) {
        final existing = _findExistingOpenInstance();
        if (existing != null) {
          return existing;
        }
      }

      // Only attempt destructive recovery for file corruption/mismatch scenarios.
      final shouldReset =
          message.contains('collection id is invalid') ||
          message.contains('schema') ||
          message.contains('corrupt') ||
          message.contains('illegalarg');

      if (!shouldReset && !message.contains('lateinitializationerror')) {
        rethrow;
      }

      await _closeExistingOpenInstances();

      await _deleteStaleDatabase(directoryPath);
      final reopened = await Isar.open(
        [KanaCardSchema],
        directory: directoryPath,
        name: _dbName,
      );
      return reopened;
    }
  }

  /// Get the already-initialized Isar instance.
  /// Call [initialize] first if not yet initialized.
  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }
    return initialize();
  }

  /// Close the database connection gracefully.
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
    }
  }

  static Isar? _findExistingOpenInstance() {
    final named = Isar.getInstance(_dbName);
    if (named != null && named.isOpen) {
      return named;
    }

    for (final name in Isar.instanceNames) {
      final instance = Isar.getInstance(name);
      if (instance != null && instance.isOpen) {
        return instance;
      }
    }

    return null;
  }

  static Future<void> _closeExistingOpenInstances() async {
    final toClose = <Isar>{};

    final named = Isar.getInstance(_dbName);
    if (named != null && named.isOpen) {
      toClose.add(named);
    }

    for (final name in Isar.instanceNames) {
      final instance = Isar.getInstance(name);
      if (instance != null && instance.isOpen) {
        toClose.add(instance);
      }
    }

    for (final instance in toClose) {
      await instance.close();
    }
  }

  static Future<void> _deleteStaleDatabase(String directoryPath) async {
    if (kIsWeb || directoryPath.isEmpty) {
      return;
    }

    final databaseFile = File('$directoryPath/kana_quest.isar');
    final lockFile = File('$directoryPath/kana_quest.isar.lock');

    if (await databaseFile.exists()) {
      await databaseFile.delete();
    }
    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  }
}
