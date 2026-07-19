import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _unreadCount = 0;

  // Called with the ticket ID when the user taps a delivered notification
  static void Function(String ticketId)? onTicketTapped;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidSettings = AndroidInitializationSettings('launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final ticketId = response.payload;
        if (ticketId != null && ticketId.isNotEmpty) {
          onTicketTapped?.call(ticketId);
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showNewTicketNotification(Map<String, dynamic> ticket) async {
    if (kIsWeb) return;

    _unreadCount++;

    final androidDetails = AndroidNotificationDetails(
      'new_ticket_channel',
      'Tiket Baru',
      channelDescription: 'Notifikasi saat ada tiket IT Helpdesk baru masuk',
      importance: Importance.high,
      priority: Priority.high,
      number: _unreadCount,
    );
    final iosDetails = DarwinNotificationDetails(badgeNumber: _unreadCount);

    await _plugin.show(
      ticket['id'].hashCode,
      'Tiket Baru: ${ticket['id'] ?? ''}',
      ticket['title'] ?? 'Ada tiket baru masuk ke antrian',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: ticket['id']?.toString(),
    );
  }

  // Call when the user has viewed their tickets, to clear the icon badge count
  static void resetUnreadCount() {
    _unreadCount = 0;
  }
}
