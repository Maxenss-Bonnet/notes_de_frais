import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _recipientEmailKey = 'recipient_email';
  static const String _defaultRecipientEmail = 'info.stagiaire.noalys@gmail.com';

  Future<void> saveRecipientEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipientEmailKey, email);
  }

  Future<String> getRecipientEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recipientEmailKey) ?? _defaultRecipientEmail;
  }
}