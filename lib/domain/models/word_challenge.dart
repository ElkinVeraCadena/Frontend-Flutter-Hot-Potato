import 'dart:math';

class WordChallenge {
  final String word;
  final String language;
  final String hint;
  final String translation;

  const WordChallenge({
    required this.word,
    required this.language,
    required this.hint,
    required this.translation,
  });

  factory WordChallenge.fromJson(Map<String, dynamic> json) {
    return WordChallenge(
      word: json['word'] as String,
      language: json['language'] as String,
      hint: json['hint'] as String,
      translation: json['translation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'language': language,
        'hint': hint,
        'translation': translation,
      };

  // ---------------------------------------------------------------------------
  // Offline word bank — used as fallback / MVP gameplay
  // ---------------------------------------------------------------------------
  static const List<WordChallenge> _wordBank = [
    WordChallenge(
      word: 'elephant',
      language: 'English',
      hint: 'Large grey animal',
      translation: 'elefante',
    ),
    WordChallenge(
      word: 'butterfly',
      language: 'English',
      hint: 'Flying insect with colorful wings',
      translation: 'mariposa',
    ),
    WordChallenge(
      word: 'mountain',
      language: 'English',
      hint: 'Very tall landform',
      translation: 'montaña',
    ),
    WordChallenge(
      word: 'library',
      language: 'English',
      hint: 'Place full of books',
      translation: 'biblioteca',
    ),
    WordChallenge(
      word: 'friendship',
      language: 'English',
      hint: 'Bond between close people',
      translation: 'amistad',
    ),
    WordChallenge(
      word: 'adventure',
      language: 'English',
      hint: 'Exciting journey or experience',
      translation: 'aventura',
    ),
    WordChallenge(
      word: 'thunder',
      language: 'English',
      hint: 'Loud sound during a storm',
      translation: 'trueno',
    ),
    WordChallenge(
      word: 'treasure',
      language: 'English',
      hint: 'Hidden valuable items',
      translation: 'tesoro',
    ),
    WordChallenge(
      word: 'whisper',
      language: 'English',
      hint: 'Speaking very softly',
      translation: 'susurro',
    ),
    WordChallenge(
      word: 'horizon',
      language: 'English',
      hint: 'Where sky meets land',
      translation: 'horizonte',
    ),
    WordChallenge(
      word: 'volcano',
      language: 'English',
      hint: 'Mountain that erupts lava',
      translation: 'volcán',
    ),
    WordChallenge(
      word: 'calendar',
      language: 'English',
      hint: 'Shows days and months',
      translation: 'calendario',
    ),
    WordChallenge(
      word: 'umbrella',
      language: 'English',
      hint: 'Keeps you dry in rain',
      translation: 'paraguas',
    ),
    WordChallenge(
      word: 'pillow',
      language: 'English',
      hint: 'You rest your head on it',
      translation: 'almohada',
    ),
    WordChallenge(
      word: 'rainbow',
      language: 'English',
      hint: 'Colorful arc after rain',
      translation: 'arcoíris',
    ),
    WordChallenge(
      word: 'airport',
      language: 'English',
      hint: 'Where planes take off and land',
      translation: 'aeropuerto',
    ),
    WordChallenge(
      word: 'champion',
      language: 'English',
      hint: 'First place winner',
      translation: 'campeón',
    ),
    WordChallenge(
      word: 'compass',
      language: 'English',
      hint: 'Shows cardinal directions',
      translation: 'brújula',
    ),
    WordChallenge(
      word: 'shadow',
      language: 'English',
      hint: 'Dark area blocked by light',
      translation: 'sombra',
    ),
    WordChallenge(
      word: 'lantern',
      language: 'English',
      hint: 'Portable light source',
      translation: 'linterna',
    ),
  ];

  static final _random = Random();

  /// Returns a shuffled list of [count] unique challenges.
  static List<WordChallenge> getShuffled({int count = 5}) {
    final shuffled = List<WordChallenge>.from(_wordBank)..shuffle(_random);
    return shuffled.take(count.clamp(1, _wordBank.length)).toList();
  }
}
