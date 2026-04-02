import 'package:flutter/material.dart';

import 'src/app/app.dart';
import 'src/core/storage/isar_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarDatabase.initialize();
  runApp(const KanaQuestApp());
}
