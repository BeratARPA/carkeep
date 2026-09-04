import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget testleri varsayılan olarak uygulama fontlarını yüklemez; metinler
/// yedek fontla ölçülür ve genişlikler gerçeğe uymaz. Taşma testleri bu yüzden
/// hem yanlış alarm verir hem gerçek taşmayı kaçırır (cihazda taşan Bluetooth
/// chip'i testte geçiyordu).
///
/// `setUpAll` içinde bir kez çağır.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final FontLoader loader = FontLoader('Manrope');
  for (final String path in const <String>[
    'assets/fonts/Manrope-Regular.ttf',
    'assets/fonts/Manrope-Medium.ttf',
    'assets/fonts/Manrope-SemiBold.ttf',
    'assets/fonts/Manrope-Bold.ttf',
    'assets/fonts/Manrope-ExtraBold.ttf',
  ]) {
    loader.addFont(
      Future<ByteData>.value(
        ByteData.sublistView(File(path).readAsBytesSync()),
      ),
    );
  }
  await loader.load();
}
