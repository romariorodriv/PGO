import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/colors.dart';
import '../constants/lima_padel_clubs.dart';
import '../utils/data_url_image.dart';
import '../utils/level_quiz_calculator.dart';
import 'level_quiz_screen.dart';

class InitialOnboardingResult {
  const InitialOnboardingResult({
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.preferredSide,
    required this.preferredClub,
    required this.category,
    required this.categoryOrigin,
    required this.categoryIsProvisional,
    this.quizCompletion,
  });

  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String preferredSide;
  final String preferredClub;
  final String category;
  final String categoryOrigin;
  final bool categoryIsProvisional;
  final LevelQuizCompletion? quizCompletion;
}

class InitialOnboardingScreen extends StatefulWidget {
  const InitialOnboardingScreen({
    super.key,
    required this.initialName,
    required this.email,
    required this.initialPhotoUrl,
    required this.initialPhone,
  });

  final String initialName;
  final String email;
  final String? initialPhotoUrl;
  final String initialPhone;

  @override
  State<InitialOnboardingScreen> createState() =>
      _InitialOnboardingScreenState();
}

class _InitialOnboardingScreenState extends State<InitialOnboardingScreen> {
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  int _step = 0;
  String? _photoUrl;
  String _side = 'Ambos';
  String _club = limaPadelClubDetails.first.name;
  String? _category;
  LevelQuizCompletion? _quizCompletion;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _email = TextEditingController(text: widget.email);
    _phone = TextEditingController(text: widget.initialPhone);
    _photoUrl = widget.initialPhotoUrl;
    _name.addListener(_refresh);
    _email.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canStep1 =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _side.isNotEmpty &&
      _club.isNotEmpty;
  bool get _canContinue => _step == 0 ? _canStep1 : _category != null;

  void _refresh() => mounted ? setState(() {}) : null;

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final lower = picked.path.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        setState(() => _photoUrl = 'data:$mime;base64,${base64Encode(bytes)}');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    Navigator.of(context).pop(
      InitialOnboardingResult(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        photoUrl: _photoUrl ?? '',
        preferredSide: _side,
        preferredClub: _club,
        category: _category ?? 'Por definir',
        categoryOrigin: _quizCompletion == null ? 'manual' : 'quiz',
        categoryIsProvisional: true,
        quizCompletion: _quizCompletion,
      ),
    );
  }

  Future<void> _openLevelQuiz() async {
    final completion = await Navigator.of(context).push<LevelQuizCompletion>(
      MaterialPageRoute(builder: (_) => const LevelQuizScreen()),
    );
    if (completion == null || !mounted) return;
    setState(() {
      _quizCompletion = completion;
      _category = LevelQuizCalculator.appCategoryLabel(
          completion.result.suggestedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              children: [
                Image.asset('assets/images/pgoIconoAPP.png', height: 64),
                const SizedBox(height: 10),
                _Dots(step: _step),
                const SizedBox(height: 20),
                if (_step == 0) _profileStep(),
                if (_step == 1) _levelStep(),
                if (_step == 2) _guideStep(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canContinue || _step == 2 ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.PrimaryGreen,
                      disabledBackgroundColor: const Color(0xFFDDE3EA),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      _step == 0
                          ? 'Guardar y continuar'
                          : _step == 1
                              ? 'Continuar'
                              : 'Comenzar recorrido',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileStep() {
    final bytes = tryDecodeDataUrl(_photoUrl);
    return Column(
      children: [
        _Title(
          title: 'Completa tu perfil',
          subtitle: 'Anade tu foto y datos basicos para empezar a jugar',
        ),
        const SizedBox(height: 18),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFF0F3F7),
              backgroundImage: bytes != null ? MemoryImage(bytes) : null,
              child: bytes == null
                  ? const Icon(Icons.add_rounded,
                      color: Color(0xFF788390), size: 46)
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: 2,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: _picking ? null : _pickPhoto,
                backgroundColor: Colors.white,
                child: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.SecondBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Haz que otros jugadores te reconozcan mas facil.',
          style: _bodyStyle(),
        ),
        const SizedBox(height: 14),
        _Field(label: 'Nombre', controller: _name),
        _Field(
          label: 'Correo registrado',
          controller: _email,
          readOnly: widget.email.isNotEmpty,
        ),
        _Field(label: 'Numero de telefono', controller: _phone),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Lado de juego'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: 'Drive', label: Text('Drive')),
                  ButtonSegment(value: 'Reves', label: Text('Reves')),
                  ButtonSegment(value: 'Ambos', label: Text('Ambos')),
                ],
                selected: {_side},
                onSelectionChanged: (value) =>
                    setState(() => _side = value.first),
              ),
            ],
          ),
        ),
        _Card(
          child: DropdownButtonFormField<String>(
            initialValue: _club,
            decoration: _inputDecoration('Club favorito'),
            items: limaPadelClubDetails
                .map((club) =>
                    DropdownMenuItem(value: club.name, child: Text(club.name)))
                .toList(),
            onChanged: (value) => setState(() => _club = value ?? _club),
          ),
        ),
      ],
    );
  }

  Widget _levelStep() {
    const items = [
      ('6TA', '6ta categoria', 'Nivel inicial / Principiante'),
      ('5TA', '5ta categoria', 'Nivel basico / Recreativo'),
      ('4TA', '4ta categoria', 'Nivel intermedio'),
      ('3RA', '3ra categoria', 'Nivel avanzado'),
      ('2DA', '2da categoria', 'Nivel competitivo'),
      ('1RA', '1ra categoria', 'Nivel alto / experto'),
      (
        '?',
        'No estoy seguro de mi nivel',
        'Te ayudamos a encontrar tu categoria ideal'
      ),
    ];
    return Column(
      children: [
        _Title(
          title: '¿Que nivel eres?',
          subtitle:
              'Selecciona el nivel que mejor te represente.\nEsto definira tu PadelRank inicial.',
        ),
        const SizedBox(height: 14),
        _InfoBox(),
        const SizedBox(height: 10),
        for (final item in items)
          _LevelTile(
            badge: item.$1,
            title: item.$2,
            subtitle: item.$3,
            selected: _category == item.$2,
            onTap: item.$1 == '?'
                ? _openLevelQuiz
                : () => setState(() {
                      _quizCompletion = null;
                      _category = item.$2;
                    }),
          ),
      ],
    );
  }

  Widget _guideStep() {
    return Column(
      children: [
        _Title(
          title: 'Te guiamos en tu\nprimera vez',
          subtitle:
              'En menos de un minuto te mostraremos como usar PGO para que empieces a jugar mas rapido.',
        ),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            children: const [
              _GuideRow(
                icon: Icons.add_home_work_outlined,
                title: 'Registrar actividad',
                body: 'Guarda tus partidos y resultados en tu historial.',
              ),
              Divider(height: 22),
              _GuideRow(
                icon: Icons.emoji_events_outlined,
                title: 'Crear o unirte a torneos',
                body: 'Encuentra torneos disponibles o arma el tuyo.',
              ),
              Divider(height: 22),
              _GuideRow(
                icon: Icons.sports_tennis_rounded,
                title: 'Buscar partidos',
                body: 'Encuentra jugadores, unete a partidos y coordina facil.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Container(
            width: 42,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color:
                  i == step ? AppColors.PrimaryGreen : const Color(0xFFE1E5EB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.06,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: _bodyStyle()),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label, required this.controller, this.readOnly = false});
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => _Card(
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: _inputDecoration(label),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: _bodyStyle());
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.blue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu nivel real se ajustara automaticamente segun tus resultados en partidos y torneos.',
                style: _bodyStyle(weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String badge;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    selected ? AppColors.PrimaryGreen : const Color(0xFFDDFD6F),
                child: Text(badge, style: _strongStyle(14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _strongStyle(16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _bodyStyle()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      );
}

class _GuideRow extends StatelessWidget {
  const _GuideRow(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFEFFBCA),
            child: Icon(icon, color: AppColors.SecondBlue, size: 38),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _strongStyle(17)),
                const SizedBox(height: 4),
                Text(body, style: _bodyStyle()),
              ],
            ),
          ),
        ],
      );
}

InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.PrimaryGreen, width: 2),
      ),
    );

TextStyle _bodyStyle({FontWeight weight = FontWeight.w500}) =>
    GoogleFonts.inter(
        color: const Color(0xFF526070), fontSize: 13, fontWeight: weight);

TextStyle _strongStyle(double size) => GoogleFonts.inter(
      color: AppColors.SecondBlue,
      fontSize: size,
      fontWeight: FontWeight.w900,
    );
