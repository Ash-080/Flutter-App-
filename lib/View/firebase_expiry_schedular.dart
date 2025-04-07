import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ✅ Initialize Local Notifications
  static Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);
  }

  // ✅ Schedule Notification for Product Expiry
  static Future<void> scheduleNotification(
      String productName, DateTime expiryDate, int notificationId) async {

    // Calculate how many days are left
    int daysLeft = expiryDate.difference(DateTime.now()).inDays;

    // Format the expiry message based on exact remaining days
    String dayText;
    if (daysLeft == 0) {
      dayText = "Today";
    } else if (daysLeft == 1) {
      dayText = "Tomorrow";
    } else {
      dayText = "$daysLeft days left";
    }

    // Set notification time (2 days before expiry)
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        expiryDate.subtract(const Duration(days: 2)), tz.local);

    if (scheduledDate.isBefore(DateTime.now())) return; // ✅ Prevent past notifications

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '⚠ Expiry Alert',
      '$productName expires $dayText!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel_id', 'Expiry Notifications',
          channelDescription: 'Notifications for product expiry',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}