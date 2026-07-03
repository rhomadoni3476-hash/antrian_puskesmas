import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotifikasiObatService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inisialisasi TimeZone
    tz.initializeTimeZones();

    // 2. Konfigurasi Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 3. Inisialisasi Plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Aksi ketika notifikasi diklik (opsional)
        debugPrint("Notifikasi diklik: ${response.payload}");
      },
    );
  }

  // Fungsi untuk menjadwalkan notifikasi obat
  Future<void> jadwalkanPengingat(
      String namaObat, int idNotifikasi, TimeOfDay waktu) async {
    final now = DateTime.now();

    // Perbaikan: Menambahkan parameter detik (0) dan milidetik (0)
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      waktu.hour,
      waktu.minute,
      0, // detik
      0, // milidetik
    );

    // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Konfigurasi Detail Notifikasi (WAJIB untuk Android 8+)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'obat_channel_id', // ID Channel
      'Pengingat Obat', // Nama Channel
      channelDescription: 'Notifikasi pengingat rutin minum obat',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Penjadwalan
    await flutterLocalNotificationsPlugin.zonedSchedule(
      idNotifikasi,
      'Waktunya Minum Obat! 💊',
      'Jangan lupa minum obat $namaObat sekarang.',
      scheduledDate,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Agar berulang tiap hari
    );
  }

  // Fungsi tambahan: Membatalkan pengingat jika resep sudah tidak berlaku
  Future<void> batalkanPengingat(int idNotifikasi) async {
    await flutterLocalNotificationsPlugin.cancel(idNotifikasi);
  }
}
