enum LevelQuizQuestionType { single, multiple }

class LevelQuizOption {
  const LevelQuizOption(this.id, this.label, this.points);
  final String id;
  final String label;
  final int points;
}

class LevelQuizQuestion {
  const LevelQuizQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.required,
    required this.options,
  });

  final String id;
  final String title;
  final String subtitle;
  final LevelQuizQuestionType type;
  final bool required;
  final List<LevelQuizOption> options;
}

class LevelQuizResult {
  const LevelQuizResult({
    required this.suggestedCategory,
    required this.preliminaryCategory,
    required this.maxAppliedCategory,
    required this.totalScore,
  });

  final String suggestedCategory;
  final String preliminaryCategory;
  final String maxAppliedCategory;
  final int totalScore;
}

class LevelQuizCalculator {
  static const questions = [
    LevelQuizQuestion(
      id: 'p1',
      title: '¿Cuánto tiempo llevas jugando pádel?',
      subtitle: 'Selecciona la opción que mejor te represente.',
      type: LevelQuizQuestionType.single,
      required: true,
      options: [
        LevelQuizOption(
            'starting', 'Recién estoy empezando / he jugado pocas veces', 0),
        LevelQuizOption('under3', 'Menos de 3 meses', 2),
        LevelQuizOption('m3to6', 'Entre 3 y 6 meses', 5),
        LevelQuizOption('m6to12', 'Entre 6 meses y 1 año', 10),
        LevelQuizOption('over1', 'Más de 1 año', 15),
        LevelQuizOption('over2', 'Más de 2 años', 18),
      ],
    ),
    LevelQuizQuestion(
      id: 'p2',
      title: '¿Con qué frecuencia juegas actualmente?',
      subtitle: 'Selecciona una opción.',
      type: LevelQuizQuestionType.single,
      required: true,
      options: [
        LevelQuizOption(
            'almostNever', 'Casi nunca / solo he jugado algunas veces', 0),
        LevelQuizOption('monthly', '1 vez al mes', 2),
        LevelQuizOption('twoThreeMonth', '2 o 3 veces al mes', 5),
        LevelQuizOption('weekly', '1 vez por semana', 8),
        LevelQuizOption('twiceWeek', '2 veces por semana', 12),
        LevelQuizOption('threeWeek', '3 o más veces por semana', 15),
      ],
    ),
    LevelQuizQuestion(
      id: 'p3',
      title: '¿Cómo sientes tu control de la pelota?',
      subtitle: 'Selecciona la opción que más se acerque a tu nivel.',
      type: LevelQuizQuestionType.single,
      required: true,
      options: [
        LevelQuizOption(
            'missMost', 'Me cuesta devolver la mayoría de pelotas', 0),
        LevelQuizOption(
            'missOften', 'Devuelvo algunas, pero fallo bastante', 5),
        LevelQuizOption('simpleRallies', 'Puedo mantener peloteos simples', 12),
        LevelQuizOption(
            'basicControl', 'Controlo dirección y velocidad básica', 20),
        LevelQuizOption('consistentIntent',
            'Coloco la pelota con intención y buena consistencia', 28),
      ],
    ),
    LevelQuizQuestion(
      id: 'p4',
      title: '¿Cómo manejas las paredes y rebotes?',
      subtitle: 'Selecciona la opción que mejor te describa.',
      type: LevelQuizQuestionType.single,
      required: true,
      options: [
        LevelQuizOption('none', 'Todavía no sé usar las paredes', 0),
        LevelQuizOption(
            'fails', 'A veces intento usarlas, pero fallo mucho', 4),
        LevelQuizOption('simple', 'Me defiendo con paredes simples', 10),
        LevelQuizOption('secure', 'Uso las paredes con cierta seguridad', 18),
        LevelQuizOption(
            'construct', 'Uso paredes y rebotes para construir puntos', 25),
      ],
    ),
    LevelQuizQuestion(
      id: 'p5',
      title: '¿Qué golpes puedes usar durante un partido?',
      subtitle: 'Puedes marcar varias opciones.',
      type: LevelQuizQuestionType.multiple,
      required: true,
      options: [
        LevelQuizOption('forehand', 'Derecha básica', 1),
        LevelQuizOption('backhand', 'Revés básico', 1),
        LevelQuizOption('volley', 'Volea', 2),
        LevelQuizOption('lob', 'Globo defensivo', 2),
        LevelQuizOption('bandeja', 'Bandeja', 3),
        LevelQuizOption('wallExit', 'Salida de pared / bajada de pared', 3),
        LevelQuizOption('smash', 'Remate', 1),
        LevelQuizOption('effect', 'Víboras o golpes con efecto', 2),
      ],
    ),
    LevelQuizQuestion(
      id: 'p6',
      title: '¿Qué experiencia tienes jugando partidos o torneos?',
      subtitle: 'Selecciona una opción.',
      type: LevelQuizQuestionType.single,
      required: true,
      options: [
        LevelQuizOption('neverFormal', 'Nunca jugué un partido formal', 0),
        LevelQuizOption('casual', 'Solo juego partidos casuales con amigos', 5),
        LevelQuizOption(
            'oftenNoCompete', 'Juego partidos seguido, pero sin competir', 10),
        LevelQuizOption(
            'internal', 'He jugado torneos internos o recreativos', 16),
        LevelQuizOption('club', 'He jugado torneos organizados de club', 22),
        LevelQuizOption('regular', 'Compito regularmente en torneos', 28),
      ],
    ),
    LevelQuizQuestion(
      id: 'p7',
      title: '¿Cómo te describirías dentro de un partido?',
      subtitle: 'Selecciona la opción que mejor te describa.',
      type: LevelQuizQuestionType.single,
      required: false,
      options: [
        LevelQuizOption('basic', 'Estoy aprendiendo lo básico', 0),
        LevelQuizOption('defense', 'Me defiendo, pero todavía fallo mucho', 0),
        LevelQuizOption('ordered', 'Puedo jugar puntos ordenados', 0),
        LevelQuizOption(
            'intermediate', 'Compito bien contra jugadores intermedios', 0),
        LevelQuizOption('strategy',
            'Juego con estrategia, consistencia y variedad de golpes', 0),
      ],
    ),
  ];

  static bool canAdvance(int index, Map<String, List<String>> answers) {
    final question = questions[index];
    if (!question.required) return true;
    return (answers[question.id] ?? const []).isNotEmpty;
  }

  static LevelQuizResult calculate(Map<String, List<String>> answers) {
    final total = _points('p1', answers) +
        _points('p2', answers) +
        _points('p3', answers) +
        _points('p4', answers) +
        _points('p5', answers).clamp(0, 14) +
        _points('p6', answers);
    final preliminary = _categoryForScore(total);
    final max = _maxCategory(answers);
    return LevelQuizResult(
      suggestedCategory: _lowerCategory(preliminary, max),
      preliminaryCategory: preliminary,
      maxAppliedCategory: max,
      totalScore: total,
    );
  }

  static int _points(String questionId, Map<String, List<String>> answers) {
    final q = questions.firstWhere((item) => item.id == questionId);
    final selected = answers[questionId] ?? const [];
    return q.options
        .where((option) => selected.contains(option.id))
        .fold(0, (sum, option) => sum + option.points);
  }

  static String _categoryForScore(int score) {
    if (score <= 39) return 'CAT_6';
    if (score <= 59) return 'CAT_5';
    if (score <= 79) return 'CAT_4';
    if (score <= 94) return 'CAT_3';
    if (score <= 109) return 'CAT_2';
    return 'CAT_1';
  }

  static String _maxCategory(Map<String, List<String>> answers) {
    final p1 = (answers['p1'] ?? const ['']).first;
    final p3 = (answers['p3'] ?? const ['']).first;
    final p4 = (answers['p4'] ?? const ['']).first;
    final p6 = (answers['p6'] ?? const ['']).first;

    if (p6 == 'neverFormal') return 'CAT_6';
    if (p1 == 'starting' || p1 == 'under3') return 'CAT_6';
    if (p1 == 'm3to6') return _strongSignals(answers) >= 3 ? 'CAT_5' : 'CAT_6';
    if (p4 == 'none' || p4 == 'fails' || p6 == 'casual') return 'CAT_5';

    final canCat4 = ['m6to12', 'over1', 'over2'].contains(p1) &&
        ['simpleRallies', 'basicControl', 'consistentIntent'].contains(p3) &&
        ['secure', 'construct'].contains(p4) &&
        ['oftenNoCompete', 'internal', 'club', 'regular'].contains(p6);
    if (!canCat4) return 'CAT_5';

    final canCat2 = ['club', 'regular'].contains(p6) &&
        ['secure', 'construct'].contains(p4) &&
        p3 == 'consistentIntent';
    if (!canCat2) return 'CAT_3';
    return 'CAT_1';
  }

  static int _strongSignals(Map<String, List<String>> answers) {
    var count = 0;
    final p2 = (answers['p2'] ?? const ['']).first;
    final p3 = (answers['p3'] ?? const ['']).first;
    final p4 = (answers['p4'] ?? const ['']).first;
    final p6 = (answers['p6'] ?? const ['']).first;
    final p5 = answers['p5'] ?? const [];
    if (p2 == 'twiceWeek' || p2 == 'threeWeek') count++;
    if (p3 == 'simpleRallies' || p3 == 'basicControl') count++;
    if (p4 == 'simple') count++;
    if (p6 == 'oftenNoCompete') count++;
    if (p5.length >= 4 && (p5.contains('volley') || p5.contains('lob'))) {
      count++;
    }
    return count;
  }

  static String _lowerCategory(String a, String max) {
    final rank = {
      'CAT_6': 6,
      'CAT_5': 5,
      'CAT_4': 4,
      'CAT_3': 3,
      'CAT_2': 2,
      'CAT_1': 1
    };
    return rank[a]! > rank[max]! ? a : max;
  }

  static String appCategoryLabel(String category) {
    return switch (category) {
      'CAT_1' => '1ra categoria',
      'CAT_2' => '2da categoria',
      'CAT_3' => '3ra categoria',
      'CAT_4' => '4ta categoria',
      'CAT_5' => '5ta categoria',
      _ => '6ta categoria',
    };
  }
}
