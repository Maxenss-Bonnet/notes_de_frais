import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _recipientEmailKey = 'recipient_email';
  static const String _recipientFirstNameKey = 'recipient_first_name';
  static const String _recipientLastNameKey = 'recipient_last_name';
  static const String _employeeEmailKey = 'employee_email';
  static const String _employeeFirstNameKey = 'employee_first_name';
  static const String _employeeLastNameKey = 'employee_last_name';
  static const String _fiscalHorsepowerKey = 'fiscal_horsepower';
  static const String _employeeEmployerKey = 'employee_employer';

  static const String _mileageRatesKey = 'mileage_rates';
  static const String _companyListKey = 'company_list';

  Future<void> saveRecipientInfo(
      {required String email, String? firstName, String? lastName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipientEmailKey, email);
    if (firstName != null) {
      await prefs.setString(_recipientFirstNameKey, firstName);
    }
    if (lastName != null) {
      await prefs.setString(_recipientLastNameKey, lastName);
    }
  }

  Future<Map<String, String>> getRecipientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email':
      prefs.getString(_recipientEmailKey) ?? 'info.stagiaire.noalys@gmail.com',
      'firstName': prefs.getString(_recipientFirstNameKey) ?? '',
      'lastName': prefs.getString(_recipientLastNameKey) ?? '',
    };
  }

  Future<void> saveEmployeeInfo(
      {String? firstName,
        String? lastName,
        String? email,
        String? fiscalHorsepower,
        String? employer}) async {
    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) {
      await prefs.setString(_employeeFirstNameKey, firstName);
    }
    if (lastName != null) {
      await prefs.setString(_employeeLastNameKey, lastName);
    }
    if (email != null) await prefs.setString(_employeeEmailKey, email);
    if (fiscalHorsepower != null) {
      await prefs.setString(_fiscalHorsepowerKey, fiscalHorsepower);
    }
    if (employer != null) {
      await prefs.setString(_employeeEmployerKey, employer);
    }
  }

  Future<Map<String, String>> getEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString(_employeeFirstNameKey) ?? '',
      'lastName': prefs.getString(_employeeLastNameKey) ?? '',
      'email': prefs.getString(_employeeEmailKey) ?? '',
      'fiscalHorsepower': prefs.getString(_fiscalHorsepowerKey) ?? '',
      'employer': prefs.getString(_employeeEmployerKey) ?? '',
    };
  }

  Future<void> saveMileageRates(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    final stringMap = rates.map((key, value) => MapEntry(key, value.toString()));
    await prefs.setString(_mileageRatesKey, json.encode(stringMap));
  }

  Future<Map<String, double>> getMileageRates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mileageRatesKey);
    if (jsonString != null) {
      final stringMap = Map<String, String>.from(json.decode(jsonString));
      return stringMap
          .map((key, value) => MapEntry(key, double.parse(value)));
    }
    return {};
  }

  Future<void> saveCompanyList(List<String> companies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_companyListKey, companies);
  }

  Future<List<String>> getCompanyList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_companyListKey) ?? [];
  }
}