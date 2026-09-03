import 'package:flutter/material.dart';

import 'core/strings_tr.dart';
import 'core/theme.dart';
import 'dev/bridge_check_screen.dart';

/// Kök widget. Yönlendirme (kurulum mu ana ekran mı) T06'da eklenir;
/// şu an T05 kontrol noktası için geçici köprü ekranı açılıyor.
class CarKeepApp extends StatelessWidget {
  const CarKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildCarKeepTheme(),
      home: const BridgeCheckScreen(),
    );
  }
}
