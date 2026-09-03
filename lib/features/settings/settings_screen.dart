/// GEÇİCİ yer tutucu. Gerçek Ayarlar ekranı T11'de (01-spec §3.7).
library;

import 'package:flutter/material.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Text(
            S.tabSettings,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
