import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../utils/level_quiz_calculator.dart';

class LevelQuizCompletion {
  const LevelQuizCompletion({
    required this.result,
    required this.answers,
  });

  final LevelQuizResult result;
  final Map<String, List<String>> answers;
}

class LevelQuizScreen extends StatefulWidget {
  const LevelQuizScreen({super.key});

  @override
  State<LevelQuizScreen> createState() => _LevelQuizScreenState();
}

class _LevelQuizScreenState extends State<LevelQuizScreen> {
  int _index = 0;
  final Map<String, List<String>> _answers = {};

  LevelQuizQuestion get _question => LevelQuizCalculator.questions[_index];

  void _next() {
    if (!LevelQuizCalculator.canAdvance(_index, _answers)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Responde esta pregunta para continuar.')),
      );
      return;
    }
    if (_index < LevelQuizCalculator.questions.length - 1) {
      setState(() => _index += 1);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelQuizResultScreen(
          completion: LevelQuizCompletion(
            result: LevelQuizCalculator.calculate(_answers),
            answers: Map.unmodifiable(_answers),
          ),
        ),
      ),
    );
  }

  void _select(String id) {
    setState(() {
      if (_question.type == LevelQuizQuestionType.multiple) {
        final values = [...?_answers[_question.id]];
        values.contains(id) ? values.remove(id) : values.add(id);
        _answers[_question.id] = values;
      } else {
        _answers[_question.id] = [id];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _answers[_question.id] ?? const [];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: Column(
                  children: [
                    Image.asset('assets/images/pgoIconoAPP.png', height: 74),
                    const SizedBox(height: 18),
                    _Progress(index: _index),
                    const SizedBox(height: 10),
                    Text('${_index + 1} de 7', style: _muted(14)),
                    const SizedBox(height: 28),
                    Text(
                      _question.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    if (!_question.required) ...[
                      const SizedBox(height: 8),
                      const _OptionalPill(),
                    ],
                    const SizedBox(height: 12),
                    Text(_question.subtitle,
                        textAlign: TextAlign.center, style: _muted(16)),
                    const SizedBox(height: 24),
                    for (final option in _question.options)
                      _AnswerCard(
                        label: option.label,
                        selected: selected.contains(option.id),
                        multi: _question.type == LevelQuizQuestionType.multiple,
                        onTap: () => _select(option.id),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      onPressed: () => setState(() => _index -= 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.SecondBlue,
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.PrimaryGreen,
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _index == 6 ? 'Finalizar' : 'Continuar',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelQuizResultScreen extends StatelessWidget {
  const LevelQuizResultScreen({super.key, required this.completion});

  final LevelQuizCompletion completion;

  @override
  Widget build(BuildContext context) {
    final category = completion.result.suggestedCategory;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
          child: Column(
            children: [
              Image.asset('assets/images/pgoIconoAPP.png', height: 82),
              const Spacer(),
              Text(
                'Tu categoría sugerida es:',
                textAlign: TextAlign.center,
                style: _muted(18),
              ),
              const SizedBox(height: 12),
              Text(
                category,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Según tus respuestas, te sugerimos empezar en $category. Tu nivel se irá ajustando con tus partidos y resultados.',
                textAlign: TextAlign.center,
                style: _muted(16),
              ),
              const Spacer(),
              _ResultButton(
                label: 'Usar esta categoría',
                filled: true,
                onTap: () => Navigator.of(context).pop(completion),
              ),
              const SizedBox(height: 10),
              _ResultButton(
                label: 'Elegir otra categoría',
                filled: false,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? AppColors.PrimaryGreen : const Color(0xFFE8ECF2),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 12,
                  offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                multi
                    ? (selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded)
                    : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                color:
                    selected ? AppColors.PrimaryGreen : const Color(0xFF8B96A5),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          7,
          (i) => Container(
            width: 34,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color:
                  i <= index ? AppColors.PrimaryGreen : const Color(0xFFE2E6EC),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
}

class _OptionalPill extends StatelessWidget {
  const _OptionalPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Opcional', style: _muted(12)),
      );
}

class _ResultButton extends StatelessWidget {
  const _ResultButton(
      {required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: filled ? AppColors.PrimaryGreen : Colors.white,
            foregroundColor: AppColors.SecondBlue,
            elevation: 0,
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.SecondBlue),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      );
}

TextStyle _muted(double size) => GoogleFonts.inter(
      color: AppColors.SecondBlue.withValues(alpha: 0.68),
      fontSize: size,
      fontWeight: FontWeight.w600,
    );
