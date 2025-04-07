import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBeepSound() async {
    await _player.play(AssetSource('sounds/beep.mp3'));
  }

  static Future<void> playNotificationSound() async {
    await _player.play(AssetSource('sounds/notification.mp3'));
  }
}
