import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Açılış sırası 02-mimari §10'da; DB, seed, drain ve worker adımları
/// T02–T15 ticket'larında eklenir.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CarKeepApp()));
}
