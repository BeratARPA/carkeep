import 'package:flutter/material.dart';

import 'core/strings_tr.dart';
import 'core/theme.dart';

/// Kök widget. Yönlendirme (kurulum mu ana ekran mı) T06'da eklenir.
class CarKeepApp extends StatelessWidget {
  const CarKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildCarKeepTheme(),
      home: const _PlaceholderScreen(),
    );
  }
}

/// T01 iskeleti; T06/T07 ile gerçek ekranlar gelir.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(S.appName, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
