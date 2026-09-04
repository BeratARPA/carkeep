# T18. Manifest'te adiyla yazili bilesenler R8 tarafindan zaten korunur; yine
# de acikca tutuluyorlar, cunku bir tanesinin adi degisirse bildirim motoru
# sessizce olur ve bunu ancak arabada fark ederiz.
-keep class com.beratarpa.carkeep.MainActivity { *; }
-keep class com.beratarpa.carkeep.BtReceiver { *; }
-keep class com.beratarpa.carkeep.NotifActionReceiver { *; }
-keep class com.beratarpa.carkeep.DailyCheckWorker { *; }
-keep class com.beratarpa.carkeep.MotionReceiver { *; }

# WorkManager isi adiyla (reflection) kuruluyor.
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }

# Flutter gomulu motoru; kendi kurallarini tasiyor ama R8 uyarilarini bastir.
-dontwarn io.flutter.embedding.**
