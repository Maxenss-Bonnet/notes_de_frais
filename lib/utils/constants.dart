const List<String> kCompanyList = [
  'Natecia',
  'Clinique du Grand Avignon',
  'Clinique des Côtes du Rhône',
  'Clinique du Pays de Montbéliard',
  'Clinique du Vivarais',
  'Noalys',
  'SCI les Docs I',
  'SCI les docs II',
  'SCI du quai',
  'SCI Module',
  'SCI de l’académie',
  'Académie',
  'Autre',
];

const Map<String, double> kMileageRates = {
  '3 CV et moins': 0.529,
  '4 CV': 0.606,
  '5 CV': 0.636,
  '6 CV': 0.665,
  '7 CV et plus': 0.697,
};

final List<String> kCvOptions = kMileageRates.keys.toList();