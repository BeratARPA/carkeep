/// GEÇİCİ yer tutucu. Gerçek Geçmiş ekranı T10'da (01-spec §3.6).
library;

import 'package:flutter/material.dart';

import '../../core/strings_tr.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Text(
            S.tabHistory,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
