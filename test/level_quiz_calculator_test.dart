import 'package:flutter_test/flutter_test.dart';
import 'package:pgo/utils/level_quiz_calculator.dart';

void main() {
  Map<String, List<String>> a({
    required String p1,
    required String p2,
    required String p3,
    required String p4,
    required List<String> p5,
    required String p6,
  }) =>
      {
        'p1': [p1],
        'p2': [p2],
        'p3': [p3],
        'p4': [p4],
        'p5': p5,
        'p6': [p6]
      };

  test('A limita a CAT_6', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'm3to6',
      p2: 'monthly',
      p3: 'missOften',
      p4: 'none',
      p5: ['forehand'],
      p6: 'casual',
    ));
    expect(r.suggestedCategory, 'CAT_6');
  });

  test('B sube a CAT_5 con señales fuertes', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'm3to6',
      p2: 'twiceWeek',
      p3: 'simpleRallies',
      p4: 'simple',
      p5: ['forehand', 'backhand', 'volley', 'lob'],
      p6: 'oftenNoCompete',
    ));
    expect(r.suggestedCategory, 'CAT_5');
  });

  test('C 6-12 meses conservador queda CAT_5', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'm6to12',
      p2: 'weekly',
      p3: 'basicControl',
      p4: 'simple',
      p5: ['forehand', 'backhand', 'volley'],
      p6: 'oftenNoCompete',
    ));
    expect(r.suggestedCategory, 'CAT_5');
  });

  test('D experiencia media queda CAT_4 o CAT_3', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'over1',
      p2: 'twiceWeek',
      p3: 'consistentIntent',
      p4: 'secure',
      p5: ['forehand', 'backhand', 'volley', 'lob', 'bandeja'],
      p6: 'internal',
    ));
    expect(['CAT_4', 'CAT_3'], contains(r.suggestedCategory));
  });

  test('E competitivo queda CAT_2 o CAT_1', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'over2',
      p2: 'threeWeek',
      p3: 'consistentIntent',
      p4: 'construct',
      p5: [
        'forehand',
        'backhand',
        'volley',
        'lob',
        'bandeja',
        'wallExit',
        'smash',
        'effect'
      ],
      p6: 'regular',
    ));
    expect(['CAT_2', 'CAT_1'], contains(r.suggestedCategory));
  });

  test('F P5 capea en 14', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'over2',
      p2: 'threeWeek',
      p3: 'consistentIntent',
      p4: 'construct',
      p5: [
        'forehand',
        'backhand',
        'volley',
        'lob',
        'bandeja',
        'wallExit',
        'smash',
        'effect'
      ],
      p6: 'regular',
    ));
    expect(r.totalScore, 128);
  });

  test('G nunca formal limita CAT_6', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'over2',
      p2: 'threeWeek',
      p3: 'consistentIntent',
      p4: 'construct',
      p5: ['forehand', 'backhand', 'volley', 'lob'],
      p6: 'neverFormal',
    ));
    expect(r.suggestedCategory, 'CAT_6');
  });

  test('H pared fallo mucho limita CAT_5', () {
    final r = LevelQuizCalculator.calculate(a(
      p1: 'over2',
      p2: 'threeWeek',
      p3: 'consistentIntent',
      p4: 'fails',
      p5: ['forehand', 'backhand', 'volley', 'lob'],
      p6: 'regular',
    ));
    expect(r.suggestedCategory, 'CAT_5');
  });
}
