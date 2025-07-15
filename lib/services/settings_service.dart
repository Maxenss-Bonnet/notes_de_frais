import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _recipientEmailKey = 'recipient_email';
  static const String _employeeEmailKey = 'employee_email';
  static const String _employeeFirstNameKey = 'employee_first_name';
  static const String _employeeLastNameKey = 'employee_last_name';
  static const String _defaultRecipientEmail = 'info.stagiaire.noalys@gmail.com';

  Future<void> saveRecipientEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipientEmailKey, email);
  }

  Future<String> getRecipientEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recipientEmailKey) ?? _defaultRecipientEmail;
  }

  Future<void> saveEmployeeInfo({String? firstName, String? lastName, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) await prefs.setString(_employeeFirstNameKey, firstName);
    if (lastName != null) await prefs.setString(_employeeLastNameKey, lastName);
    if (email != null) await prefs.setString(_employeeEmailKey, email);
  }

  Future<Map<String, String>> getEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString(_employeeFirstNameKey) ?? '',
      'lastName': prefs.getString(_employeeLastNameKey) ?? '',
      'email': prefs.getString(_employeeEmailKey) ?? '',
    };
  }
}