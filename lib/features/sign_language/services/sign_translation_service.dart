class SignTranslationService {
  SignTranslationService();

  static const Map<String, String> _idToEnDictionary = {
    // ── BISINDO & SIBI Core Vocabulary ─────────────────────────────────────
    'halo': 'Hello',
    'terima kasih': 'Thank you',
    'terima': 'Thank',
    'kasih': 'Give',
    'apa kabar': 'How are you',
    'kabar': 'News',
    'baik': 'Good',
    'siapa': 'Who',
    'apa': 'What',
    'dimana': 'Where',
    'mana': 'Where',
    'kemana': 'Where to',
    'kapan': 'When',
    'berapa': 'How much',
    'bagaimana': 'How',
    'kenapa': 'Why',
    'mengapa': 'Why',

    // Pronouns
    'saya': 'I',
    'aku': 'I',
    'kamu': 'You',
    'dia': 'They',
    'kami': 'We',
    'kita': 'We',
    'kalian': 'You all',
    'mereka': 'They',

    // Actions & Daily Activities
    'makan': 'Eat',
    'minum': 'Drink',
    'air': 'Water',
    'duduk': 'Sit',
    'berdiri': 'Stand',
    'berhenti': 'Stop',
    'mandi': 'Bath',
    'tidur': 'Sleep',
    'jalan': 'Walk',
    'bantu': 'Help',
    'tolong': 'Help',
    'tunggu': 'Wait',
    'lihat': 'Look',
    'bicara': 'Speak',
    'datang': 'Come',
    'pergi': 'Go',

    // Health & Emergency
    'sakit': 'Sick',
    'pusing': 'Dizzy',
    'sehat': 'Healthy',
    'sesak': 'Short of breath',
    'nafas': 'Breathe',
    'obat': 'Medicine',
    'dokter': 'Doctor',
    'darurat': 'Emergency',
    'polisi': 'Police',
    'hilang': 'Lost',
    'sesat': 'Lost',
    'lelah': 'Tired',
    'haus': 'Thirsty',
    'pendamping': 'Companion',

    // Places & Transportation
    'rumah': 'House',
    'rumah sakit': 'Hospital',
    'hotel': 'Hotel',
    'kamar': 'Room',
    'masjid': 'Mosque',
    'bus': 'Bus',
    'arah': 'Direction',

    // Religious & Cultural
    'shalat': 'Prayer',
    'wudhu': 'Ablution',

    // Common Affirmatives / Negatives
    'ya': 'Yes',
    'tidak': 'No',
    'bukan': 'Not',
    'tuli': 'Deaf',
    'dengar': 'Hearing',
    'di': 'In',
    'ke': 'To',
    'dari': 'From',
    'kan': 'Right',

    // ── Cafe & Cashier Vocabulary ──────────────────────────────────────────
    'kopi': 'Coffee',
    'teh': 'Tea',
    'susu': 'Milk',
    'gula': 'Sugar',
    'es': 'Ice',
    'panas': 'Hot',
    'dingin': 'Cold',
    'pesan kopi': 'Order coffee',
    'pesan kopi satu': 'Order one coffee',
    'pesan': 'Order',
    'less ice': 'Less ice',
    'kurang gula': 'Less sugar',
    'sedikit es': 'Less ice',
    'bayar qris': 'Pay with QRIS',
    'qris': 'QRIS',
    'bayar': 'Pay',
    'uang': 'Money',
    'kembalian': 'Change',
    'struk': 'Receipt',
    'total': 'Total',
    'beli': 'Buy',

    // ── Full Sample Sentences ──────────────────────────────────────────────
    'saya mau beli tiket': 'I want to buy a ticket',
    'saya mau pesan kopi': 'I would like to order coffee',
    'tolong esnya sedikit saja ya': 'Please give me less ice',
    'tolong kurangi gulanya ya': 'Please make it with less sugar',
    'saya ingin bayar menggunakan qris': 'I want to pay using QRIS',
    'saya mau bayar menggunakan qris': 'I want to pay using QRIS',
    'tolong dibungkus untuk dibawa pulang': 'Please pack it for takeaway',
    'bawa pulang': 'Takeaway',
    'halo, terima kasih. saya mau bayar menggunakan qris.':
        'Hello, thank you. I want to pay using QRIS.',
    'silakan tunjukkan ktp asli anda': 'Please show your original ID card',
  };

  static final Map<String, String> _enToIdDictionary = () {
    final map = <String, String>{};
    for (final entry in _idToEnDictionary.entries) {
      map[entry.value.toLowerCase()] = entry.key;
    }
    return map;
  }();

  /// Translates Indonesian sign token/phrase to English.
  /// If no dictionary entry exists, tries word-by-word token translation,
  /// or falls back to preserving the original text.
  String translateToEnglish(String indonesianText) {
    final trimmed = indonesianText.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();

    // 1. Exact phrase match
    if (_idToEnDictionary.containsKey(lower)) {
      return _idToEnDictionary[lower]!;
    }

    // 2. Tokenized word-by-word translation
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 1) {
      final translatedWords = words.map((w) {
        final clean = w.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
        if (_idToEnDictionary.containsKey(clean)) {
          return _idToEnDictionary[clean]!;
        }
        return w;
      }).toList();
      return translatedWords.join(' ');
    }

    // Single word without punctuation
    final singleClean = lower.replaceAll(RegExp(r'[^\w]'), '');
    if (_idToEnDictionary.containsKey(singleClean)) {
      return _idToEnDictionary[singleClean]!;
    }

    return trimmed;
  }

  /// Translates English text back to Indonesian if an entry exists.
  String translateToIndonesian(String englishText) {
    final trimmed = englishText.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (_enToIdDictionary.containsKey(lower)) {
      final idWord = _enToIdDictionary[lower]!;
      // Capitalize first letter
      return idWord.isNotEmpty
          ? '${idWord[0].toUpperCase()}${idWord.substring(1)}'
          : idWord;
    }

    return trimmed;
  }

  /// Returns localized text based on the target language code ('id' or 'en').
  String getLocalizedText(String text, {required String languageCode}) {
    if (languageCode.startsWith('en')) {
      return translateToEnglish(text);
    }
    return text;
  }
}
