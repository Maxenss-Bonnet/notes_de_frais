import 'dart:math' as math;

class StringNormalizer {
  static final Map<String, String> _merchantKeywords = {
    // Restauration Rapide & Boulangeries
    'mcdonald': "McDonald's",
    'mcdo': "McDonald's",
    'quick': 'Quick',
    'burger king': 'Burger King',
    'kfc': 'KFC',
    'subway': 'Subway',
    'o\'tacos': 'O\'Tacos',
    'five guys': 'Five Guys',
    'domino\'s': "Domino's Pizza",
    'pizza hut': 'Pizza Hut',
    'la boite a pizza': 'La Boîte à Pizza',
    'starbucks': 'Starbucks',
    'columbus cafe': 'Columbus Café',
    'paul': 'Paul',
    'brioche doree': 'Brioche Dorée',
    'la mie caline': 'La Mie Câline',
    'marie blachere': 'Marie Blachère',
    'patapain': "Patàpain",
    'pret a manger': 'Pret A Manger',
    'exki': 'EXKi',
    'eat salad': 'Eat Salad',
    'pokawa': 'Pokawa',
    'bagelstein': 'Bagelstein',

    // Chaînes de Restaurants
    'hippopotamus': 'Hippopotamus',
    'buffalo grill': 'Buffalo Grill',
    'courtepaille': 'Courtepaille',
    'del arte': 'Ristorante Del Arte',
    'le bistrot du boucher': 'Le Bistrot du Boucher',
    'au bureau': 'Au Bureau',
    'la boucherie': 'La Boucherie',
    'leon de bruxelles': 'Léon',
    'vapiano': 'Vapiano',
    'flunch': 'Flunch',
    'sushi shop': 'Sushi Shop',
    'planet sushi': 'Planet Sushi',
    'pedra alta': 'Pedra Alta',
    'la criee': 'La Criée',
    'chez clement': 'Chez Clément',
    'big mamma': 'Big Mamma',
    'memphis coffee': 'Memphis Coffee',

    // Grande Distribution & Supérettes
    'carrefour': 'Carrefour',
    'auchan': 'Auchan',
    'leclerc': 'E.Leclerc',
    'intermarche': 'Intermarché',
    'systeme u': 'Super U',
    'super u': 'Super U',
    'hyper u': 'Hyper U',
    'lidl': 'Lidl',
    'aldi': 'Aldi',
    'monoprix': 'Monoprix',
    'franprix': 'Franprix',
    'casino': 'Casino',
    'geant casino': 'Géant Casino',
    'picard': 'Picard',
    'thiriet': 'Thiriet',
    'naturalia': 'Naturalia',
    'biocoop': 'Biocoop',
    'la vie claire': 'La Vie Claire',

    // Transport Aérien
    'air france': 'Air France',
    'easyjet': 'EasyJet',
    'ryanair': 'Ryanair',
    'transavia': 'Transavia',
    'lufthansa': 'Lufthansa',
    'klm': 'KLM',
    'british airways': 'British Airways',
    'vueling': 'Vueling',
    'volotea': 'Volotea',
    'emirates': 'Emirates',
    'qatar airways': 'Qatar Airways',
    'air canada': 'Air Canada',

    // Transport Ferroviaire & Terrestre
    'sncf': 'SNCF',
    'ouigo': 'Ouigo',
    'thalys': 'Thalys',
    'eurostar': 'Eurostar',
    'trenitalia': 'Trenitalia',
    'deutsche bahn': 'Deutsche Bahn',
    'ratp': 'RATP',
    'tcl': 'TCL (Lyon)',
    'blablacar': 'BlaBlaCar',
    'flixbus': 'FlixBus',

    // Taxis & VTC
    'uber': 'Uber',
    'bolt': 'Bolt',
    'freenow': 'FreeNow',
    'g7': 'Taxis G7',
    'lecab': 'LeCab',

    // Location de véhicules
    'hertz': 'Hertz',
    'avis': 'Avis',
    'europcar': 'Europcar',
    'sixt': 'Sixt',
    'enterprise': 'Enterprise',
    'ada': 'ADA',
    'getaround': 'Getaround',
    'ouicar': 'Ouicar',

    // Hôtellerie
    'accor': 'Accor Hotels',
    'ibis': 'Ibis',
    'mercure': 'Mercure',
    'novotel': 'Novotel',
    'sofitel': 'Sofitel',
    'pullman': 'Pullman',
    'f1': 'Hôtel F1',
    'b&b': 'B&B Hotels',
    'kyriad': 'Kyriad',
    'campanile': 'Campanile',
    'premiere classe': 'Première Classe',
    'marriott': 'Marriott',
    'hilton': 'Hilton',
    'best western': 'Best Western',
    'radisson': 'Radisson',
    'booking.com': 'Booking.com',
    'airbnb': 'Airbnb',
    'hotels.com': 'Hotels.com',
    'expedia': 'Expedia',

    // Électronique & Fournitures
    'amazon': 'Amazon',
    'fnac': 'FNAC',
    'darty': 'Darty',
    'boulanger': 'Boulanger',
    'apple': 'Apple',
    'ldlc': 'LDLC',
    'materiel.net': 'Materiel.net',
    'bureau vallee': 'Bureau Vallée',
    'office depot': 'Office Depot',
    'top office': 'Top Office',
    'staples': 'Staples',
    'lyreco': 'Lyreco',
    'viking': 'Viking',

    // Bricolage, Mobilier & Décoration
    'leroy merlin': 'Leroy Merlin',
    'castorama': 'Castorama',
    'bricoman': 'Bricoman',
    'brico depot': 'Brico Dépôt',
    'ikea': 'IKEA',
    'but': 'BUT',
    'conforama': 'Conforama',
    'maisons du monde': 'Maisons du Monde',

    // Sport, Culture & Loisirs
    'decathlon': 'Decathlon',
    'go sport': 'Go Sport',
    'intersport': 'Intersport',
    'foot locker': 'Foot Locker',
    'cultura': 'Cultura',
    'sephora': 'Sephora',
    'nocibe': 'Nocibé',
    'marionnaud': 'Marionnaud',

    // Stations-service & Péages
    'totalenergies': 'TotalEnergies',
    'total': 'TotalEnergies',
    'shell': 'Shell',
    'esso': 'Esso',
    'avia': 'Avia',
    'bp': 'BP',
    'agip': 'Agip',
    'eni': 'Eni',
    'vinci autoroutes': 'Vinci Autoroutes',
    'aprr': 'APRR',
    'sanef': 'SANEF',
    'area': 'AREA',
    'asf': 'ASF',

    // Télécommunications
    'orange': 'Orange',
    'sfr': 'SFR',
    'bouygues telecom': 'Bouygues Telecom',
    'bouygues': 'Bouygues Telecom',
    'free': 'Free',

    // Services
    'qrm': 'QR-Facture',
    'la poste': 'La Poste',
    'chronopost': 'Chronopost',
    'dhl': 'DHL',
    'fedex': 'FedEx',
    'ups': 'UPS',
    'parking indigo': 'Parking Indigo',
    'q-park': 'Q-Park',
    'effia': 'Parking Effia',
    'selecta': 'Selecta',
  };

  static String normalizeMerchantName(String merchantName) {
    String cleanedName = merchantName.toLowerCase()
        .replaceAll('.', ' ').replaceAll('-', ' ').replaceAll(',', ' ')
        .replaceAll(RegExp(r'\b(sas|sarl|sa|inc|ltd|llc)\b'), '')
        .trim();

    // 1. Recherche par mot-clé direct
    for (var entry in _merchantKeywords.entries) {
      if (cleanedName.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Recherche par similarité (Distance de Levenshtein)
    String? bestMatch;
    int minDistance = 3;

    for (var entry in _merchantKeywords.entries) {
      int distance = _levenshtein(cleanedName, entry.key);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = entry.value;
      }
    }
    if (bestMatch != null) {
      return bestMatch;
    }

    // 3. Nettoyage final si aucune correspondance
    return cleanedName.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  static int _levenshtein(String s1, String s2) {
    if (s1 == s2) {
      return 0;
    }
    if (s1.isEmpty) {
      return s2.length;
    }
    if (s2.isEmpty) {
      return s1.length;
    }

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}