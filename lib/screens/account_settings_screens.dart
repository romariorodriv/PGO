// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/profile_summary.dart';
import '../services/account_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/support_service.dart';
import 'login_screen.dart';

class SportsPreferencesScreen extends StatefulWidget {
  const SportsPreferencesScreen({super.key, required this.profile});

  final ProfileSummary profile;

  @override
  State<SportsPreferencesScreen> createState() =>
      _SportsPreferencesScreenState();
}

class _SportsPreferencesScreenState extends State<SportsPreferencesScreen> {
  final ProfileService _profileService = ProfileService();
  late String _side;
  late String _schedule;
  late String _club;
  late String _format;
  bool _allowInvites = true;
  bool _recommendTournaments = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _side = _normalizeSide(widget.profile.preferredSide);
    _schedule = 'Mañana';
    _club = widget.profile.preferredClub?.trim().isNotEmpty == true
        ? widget.profile.preferredClub!.trim()
        : 'One Padel Olguín';
    _format = 'Dobles';
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _schedule = prefs.getString('sports_schedule') ?? _schedule;
      _format = prefs.getString('sports_format') ?? _format;
      _allowInvites = prefs.getBool('sports_allow_invites') ?? true;
      _recommendTournaments =
          prefs.getBool('sports_recommend_tournaments') ?? false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sports_schedule', _schedule);
      await prefs.setString('sports_format', _format);
      await prefs.setBool('sports_allow_invites', _allowInvites);
      await prefs.setBool(
          'sports_recommend_tournaments', _recommendTournaments);
      await _profileService.updateMyProfile(
        name: widget.profile.name,
        photoUrl: widget.profile.photoUrl,
        category: widget.profile.category,
        preferredClub: _club,
        preferredSide: _side,
        racketModel: widget.profile.racketModel,
        experienceLevel: widget.profile.experienceLevel,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.profile.category?.trim().isNotEmpty == true
        ? widget.profile.category!.trim()
        : 'Sin categoría';

    return _SettingsScaffold(
      compact: true,
      title: 'Preferencias deportivas',
      body: [
        _SettingsCard(
          dense: true,
          children: [
            Text(
              'Configura cómo juegas para recibir mejores partidos, torneos e invitaciones.',
              style: PgoTextStyles.body(
                color: AppColors.SecondBlue,
                weight: FontWeight.w500,
              ).copyWith(fontSize: 13.5, height: 1.2),
            ),
            const SizedBox(height: 14),
            _SectionLabel('Categoría actual'),
            const SizedBox(height: 10),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8CB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  const Icon(Icons.emoji_events,
                      color: Color(0xFF9AC12A), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: PgoTextStyles.title(
                      color: AppColors.SecondBlue,
                      weight: FontWeight.w900,
                    ).copyWith(fontSize: 15.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Tu categoría podrá actualizarse según tus resultados.',
                textAlign: TextAlign.center,
                style: PgoTextStyles.bodySecondary(
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 11.5, height: 1.15),
              ),
            ),
            const _SoftDivider(),
            _SectionLabel('Lado de juego'),
            const SizedBox(height: 10),
            _SegmentedSelector(
              value: _side,
              options: const ['Drive', 'Revés', 'Ambos'],
              compact: true,
              onChanged: (value) => setState(() => _side = value),
            ),
            const _SoftDivider(),
            _SectionLabel('Horario habitual'),
            const SizedBox(height: 10),
            _SegmentedSelector(
              value: _schedule,
              options: const ['Mañana', 'Tarde', 'Noche'],
              compact: true,
              onChanged: (value) => setState(() => _schedule = value),
            ),
            const _SoftDivider(),
            _SectionLabel('Club favorito'),
            const SizedBox(height: 10),
            _DropdownField(
              value: _club,
              options: const [
                'One Padel Olguín',
                'One Padel Trigal',
                'Padel 360',
                'Lima Padel',
              ],
              icon: Icons.location_on,
              compact: true,
              onChanged: (value) => setState(() => _club = value),
            ),
            const _SoftDivider(),
            _SectionLabel('Formato preferido'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: ['Dobles', 'Mixto', 'Americano']
                  .map(
                    (item) => _ChoicePill(
                      label: item,
                      selected: _format == item,
                      compact: true,
                      onTap: () => setState(() => _format = item),
                    ),
                  )
                  .toList(),
            ),
            const _SoftDivider(),
            _SwitchRow(
              icon: Icons.person_outline,
              title: 'Permitir invitaciones a partidos',
              subtitle: 'Otros jugadores podrán invitarte a sus partidos',
              value: _allowInvites,
              compact: true,
              onChanged: (value) => setState(() => _allowInvites = value),
            ),
            const _SoftDivider(height: 16),
            _SwitchRow(
              icon: Icons.emoji_events,
              iconBackground: const Color(0xFFE9F8CB),
              title: 'Recibir recomendaciones de torneos',
              subtitle: 'Te recomendaremos torneos según tu preferencia',
              value: _recommendTournaments,
              compact: true,
              onChanged: (value) =>
                  setState(() => _recommendTournaments = value),
            ),
          ],
        ),
      ],
      bottomButtonLabel: 'Guardar preferencias',
      bottomLoading: _isSaving,
      onBottomTap: _save,
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<String, bool> _values = {
    'match_joined': true,
    'match_full': true,
    'match_reminder': true,
    'score_required': true,
    'tournament_recommended': true,
    'next_match': true,
    'result_confirmed': true,
    'schedule_changes': true,
    'friend_requests': true,
    'match_invites': true,
    'followers': true,
    'news': true,
    'promos': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _values.keys) {
        _values[key] = prefs.getBool('notif_$key') ?? _values[key]!;
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _values.entries) {
      await prefs.setBool('notif_${entry.key}', entry.value);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Ajustes de notificaciones',
      subtitle: 'Elige qué alertas quieres recibir dentro de PGO.',
      compact: true,
      body: [
        _NotificationGroup(
          icon: Icons.sports_tennis,
          title: 'Partidos',
          color: const Color(0xFFD9ECFF),
          dense: true,
          rows: [
            _SettingSwitchSpec('match_joined', Icons.person_outline,
                'Cuando alguien se une a mi partido'),
            _SettingSwitchSpec('match_full', Icons.check_circle_outline,
                'Cuando un partido se completa'),
            _SettingSwitchSpec('match_reminder', Icons.schedule,
                'Recordatorio antes del partido'),
            _SettingSwitchSpec('score_required', Icons.description_outlined,
                'Cuando debo registrar el resultado'),
          ],
          values: _values,
          onChanged: _setValue,
        ),
        _NotificationGroup(
          icon: Icons.emoji_events,
          title: 'Torneos',
          color: const Color(0xFFE9F8CB),
          dense: true,
          rows: [
            _SettingSwitchSpec('tournament_recommended',
                Icons.emoji_events_outlined, 'Nuevos torneos recomendados'),
            _SettingSwitchSpec('next_match', Icons.event_available_outlined,
                'Siguiente partido asignado'),
            _SettingSwitchSpec('result_confirmed', Icons.check_circle_outline,
                'Resultado confirmado'),
            _SettingSwitchSpec('schedule_changes', Icons.schedule,
                'Cambios de horario o cancha'),
          ],
          values: _values,
          onChanged: _setValue,
        ),
        _NotificationGroup(
          icon: Icons.person_outline,
          title: 'Social',
          color: const Color(0xFFD9ECFF),
          dense: true,
          rows: [
            _SettingSwitchSpec('friend_requests', Icons.person_add_alt,
                'Solicitudes de amistad'),
            _SettingSwitchSpec('match_invites', Icons.event_available_outlined,
                'Invitaciones para jugar'),
            _SettingSwitchSpec(
                'followers', Icons.group_outlined, 'Nuevos seguidores'),
          ],
          values: _values,
          onChanged: _setValue,
        ),
        _NotificationGroup(
          icon: null,
          title: 'PGO',
          color: const Color(0xFFD9ECFF),
          label: 'PGO',
          dense: true,
          rows: [
            _SettingSwitchSpec(
                'news', Icons.campaign_outlined, 'Novedades importantes'),
            _SettingSwitchSpec('promos', Icons.sell_outlined, 'Promociones'),
          ],
          values: _values,
          onChanged: _setValue,
        ),
      ],
      bottomButtonLabel: 'Guardar cambios',
      onBottomTap: _save,
    );
  }

  void _setValue(String key, bool value) {
    setState(() => _values[key] = value);
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final Map<String, bool> _values = {
    'private_account': false,
    'show_category': true,
    'show_club': true,
    'show_history': true,
    'show_winrate': true,
    'allow_invites': true,
    'allow_friend_requests': true,
    'allow_search': true,
    'approx_location': true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _values.keys) {
        _values[key] = prefs.getBool('privacy_$key') ?? _values[key]!;
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _values.entries) {
      await prefs.setBool('privacy_${entry.key}', entry.value);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Privacidad',
      subtitle: 'Controla tu visibilidad e interacciones dentro de PGO.',
      compact: true,
      body: [
        _SettingsCard(
          title: 'Privacidad de la cuenta',
          dense: true,
          children: [
            _SwitchRow(
              icon: Icons.lock_outline,
              title: 'Cuenta privada',
              value: _values['private_account']!,
              onChanged: (value) => _set('private_account', value),
              compact: true,
            ),
            const SizedBox(height: 10),
            Text(
              'Otros jugadores podrán encontrar tu perfil y ver la información pública que permitas.',
              style: PgoTextStyles.bodySecondary(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
              ),
            ),
            const _SoftDivider(),
            _SectionLabel('Perfil publico'),
            _SettingsSwitchTile(
                Icons.auto_awesome_outlined,
                'Mostrar mi categoría',
                _values['show_category']!,
                (value) => _set('show_category', value)),
            _SettingsSwitchTile(
                Icons.location_on_outlined,
                'Mostrar mi club favorito',
                _values['show_club']!,
                (value) => _set('show_club', value)),
            _SettingsSwitchTile(
                Icons.bar_chart_rounded,
                'Mostrar mi historial deportivo',
                _values['show_history']!,
                (value) => _set('show_history', value)),
            _SettingsSwitchTile(
                Icons.percent_rounded,
                'Mostrar mi win rate',
                _values['show_winrate']!,
                (value) => _set('show_winrate', value)),
          ],
        ),
        _SettingsCard(
          title: 'Interacciones',
          dense: true,
          children: [
            _SettingsSwitchTile(
                Icons.sports_tennis,
                'Permitir que me inviten a partidos',
                _values['allow_invites']!,
                (value) => _set('allow_invites', value)),
            _SettingsSwitchTile(
                Icons.person_add_alt,
                'Permitir solicitudes de amistad',
                _values['allow_friend_requests']!,
                (value) => _set('allow_friend_requests', value)),
            _SettingsSwitchTile(
                Icons.search,
                'Permitir que me encuentren por nombre',
                _values['allow_search']!,
                (value) => _set('allow_search', value)),
          ],
        ),
        _SettingsCard(
          title: 'Localización',
          dense: true,
          children: [
            _SwitchRow(
              icon: Icons.location_on_outlined,
              title: 'Ubicación aproximada',
              value: _values['approx_location']!,
              onChanged: (value) => _set('approx_location', value),
              compact: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Activa esta opción para permitir que PGO use la ubicación de tu dispositivo. Nos permitirá recomendarte partidos y torneos cerca de ti.',
              style: PgoTextStyles.bodySecondary(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        _SettingsCard(
          dense: true,
          children: [
            _ActionRow(
              icon: Icons.shield_outlined,
              title: 'Usuarios bloqueados',
              onTap: () =>
                  _showSnack(context, 'No tienes usuarios bloqueados.'),
            ),
          ],
        ),
      ],
      bottomButtonLabel: 'Guardar cambios',
      onBottomTap: _save,
    );
  }

  void _set(String key, bool value) => setState(() => _values[key] = value);
}

class SecurityAccessScreen extends StatelessWidget {
  const SecurityAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Seguridad y acceso',
      subtitle: 'Administra tu contraseña y protege el acceso a tu cuenta.',
      compact: true,
      body: [
        _SettingsCard(
          title: 'Seguridad e inicio de sesión',
          dense: true,
          children: [
            _ActionRow(
              icon: Icons.lock_outline,
              title: 'Cambiar contraseña',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
          ],
        ),
        _SettingsCard(
          title: 'Zona de peligro',
          dense: true,
          children: [
            _ActionRow(
              icon: Icons.delete_outline,
              title: 'Eliminar cuenta',
              danger: true,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Solicita la eliminación permanente de tu cuenta y de todos tus datos.',
              style: PgoTextStyles.bodySecondary(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final AccountService _accountService = AccountService();
  bool _isSaving = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _isValid => _hasMinLength && _hasNumber && _hasUpper;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _accountService.changePassword(_passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _showSnack(context, 'Contrasena actualizada.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Cambiar contraseña',
      subtitle: 'Crea una contraseña segura para proteger tu cuenta.',
      compact: true,
      body: [
        _SettingsTextField(
          controller: _passwordController,
          hint: 'Contraseña',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        _PasswordRule(valid: _hasMinLength, text: 'Mínimo 8 caracteres'),
        _PasswordRule(valid: _hasNumber, text: 'Mínimo 1 número'),
        _PasswordRule(valid: _hasUpper, text: 'Mínimo 1 mayúscula'),
      ],
      bottomButtonLabel: 'Cambiar contraseña',
      bottomLoading: _isSaving,
      bottomEnabled: _isValid,
      onBottomTap: _save,
    );
  }
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final SupportService _supportService = SupportService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _type = 'Partido';
  XFile? _screenshot;
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _isSending) {
      _showSnack(context, 'Completa asunto y descripción.');
      return;
    }
    setState(() => _isSending = true);
    try {
      await _supportService.sendReport(
        type: _type,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        screenshotLabel: _screenshot?.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _showSnack(context, 'Reporte enviado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickScreenshot() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (!mounted || image == null) return;
    setState(() => _screenshot = image);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Reportar un problema',
      subtitle: 'Cuéntanos qué ocurrió y te ayudaremos a revisarlo.',
      compact: true,
      body: [
        _SettingsCard(
          title: 'Tipo de problema',
          dense: true,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                'Partido',
                'Torneo',
                'Resultado',
                'Perfil',
                'Error técnico',
                'Otro'
              ]
                  .map(
                    (item) => SizedBox(
                      width: 124,
                      child: _ChoicePill(
                        label: item,
                        selected: _type == item,
                        onTap: () => setState(() => _type = item),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            _SectionLabel('Asunto'),
            const SizedBox(height: 10),
            _SettingsTextField(
              controller: _subjectController,
              hint: 'Ej. No pude unirme a un partido',
            ),
            const SizedBox(height: 18),
            _SectionLabel('Descripción'),
            const SizedBox(height: 10),
            _SettingsTextField(
              controller: _descriptionController,
              hint:
                  'Descríbenos qué pasó, en qué pantalla ocurrió y qué intentabas hacer.',
              maxLines: 6,
              maxLength: 1000,
            ),
            const SizedBox(height: 18),
            _SectionLabel('Adjuntar captura (opcional)'),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickScreenshot,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD5DAE2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE1E5EB),
                      child: Icon(
                        Icons.upload_rounded,
                        color: AppColors.SecondBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _screenshot == null
                            ? 'Subir imagen\nPNG, JPG o JPEG · Máx. 10 MB'
                            : '${_screenshot!.name}\nImagen seleccionada',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.bodySecondary(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_screenshot != null)
                      IconButton(
                        onPressed: () => setState(() => _screenshot = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _InfoStrip(
              'Mientras más detalle incluyas, más rápido podremos ayudarte.',
            ),
          ],
        ),
      ],
      bottomButtonLabel: 'Enviar reporte',
      bottomLoading: _isSending,
      onBottomTap: _send,
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Ayuda',
      subtitle: 'Encuentra respuestas rápidas y soporte para usar PGO.',
      compact: true,
      body: [
        _SettingsCard(
          title: 'Preguntas frecuentes',
          dense: true,
          children: const [
            _FaqItem(
              icon: Icons.sports_tennis,
              title: '¿Cómo crear un partido?',
              body:
                  'Ve a Partidos y toca el botón +. Completa la categoría, fecha, hora, sede, cupos y costo estimado. Luego publica el partido para que otros jugadores puedan unirse.',
            ),
            _FaqItem(
              icon: Icons.group_outlined,
              title: '¿Cómo unirme a un partido?',
              body:
                  'Entra a Partidos disponibles, elige un partido compatible con tu categoría y revisa la sede, hora y costo. Si todo está correcto, toca Unirme al partido.',
            ),
            _FaqItem(
              icon: Icons.check_circle_outline,
              title: '¿Cómo registrar un resultado?',
              body:
                  'Cuando termine el partido, entra a Mi partido y toca Registrar resultado. Ingresa el marcador, selecciona a los ganadores y confirma para actualizar tu historial.',
            ),
            _FaqItem(
              icon: Icons.event_available_outlined,
              title: '¿Cómo inscribirme a un torneo?',
              body:
                  'Ve a Torneos, elige el torneo que te interesa y revisa la categoría, fecha, sede y cupos. Si cumples los requisitos, toca Unirme.',
            ),
            _FaqItem(
              icon: Icons.emoji_events_outlined,
              title: '¿Cómo crear un torneo?',
              body:
                  'Desde Torneos, toca el botón +. Completa el nombre, formato, categoría, fecha, hora, sede y cantidad de jugadores. Luego podrás guardar el torneo o publicarlo.',
            ),
            _FaqItem(
              icon: Icons.auto_awesome_outlined,
              title: '¿Cómo funciona mi categoría?',
              body:
                  'Tu categoría representa tu nivel dentro de PGO. Se usa para recomendarte partidos y torneos compatibles. Más adelante podrá actualizarse según tus resultados e historial deportivo.',
            ),
          ],
        ),
        _SettingsCard(
          title: 'Soporte',
          dense: true,
          children: [
            _ActionRow(
              icon: Icons.chat_bubble_outline,
              title: 'Chatear con soporte',
              onTap: () =>
                  _showSnack(context, 'Soporte estará disponible pronto.'),
            ),
          ],
        ),
        const _InfoStrip('Tiempo de respuesta estimado: menos de 24 horas.'),
      ],
      bottomButtonLabel: 'Contactar soporte',
      onBottomTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
      ),
    );
  }
}

class SimpleLegalScreen extends StatelessWidget {
  const SimpleLegalScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: title,
      body: [
        _SettingsCard(
          children: [
            Text(body, style: _bodyStyle(height: 1.35)),
          ],
        ),
      ],
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.compact = false,
    this.bottomButtonLabel,
    this.bottomEnabled = true,
    this.bottomLoading = false,
    this.onBottomTap,
  });

  final String title;
  final String? subtitle;
  final List<Widget> body;
  final bool compact;
  final String? bottomButtonLabel;
  final bool bottomEnabled;
  final bool bottomLoading;
  final VoidCallback? onBottomTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 24,
                    compact ? 14 : 18,
                    compact ? 20 : 24,
                    bottomButtonLabel == null ? (compact ? 24 : 32) : 120,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.SecondBlue,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Text(
                      title,
                      style: PgoTextStyles.title(
                        color: AppColors.SecondBlue,
                        weight: FontWeight.w900,
                      ).copyWith(fontSize: compact ? 30 : 34),
                    ),
                    if ((subtitle ?? '').isNotEmpty) ...[
                      SizedBox(height: compact ? 8 : 10),
                      Text(
                        subtitle!,
                        style: PgoTextStyles.body(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w500,
                        ).copyWith(fontSize: compact ? 14 : 16, height: 1.2),
                      ),
                    ],
                    SizedBox(height: compact ? 22 : 34),
                    ...body,
                  ],
                ),
              ),
              if (bottomButtonLabel != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 20 : 24,
                      8,
                      compact ? 20 : 24,
                      18,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: compact ? 54 : 60,
                      child: ElevatedButton(
                        onPressed: bottomEnabled && !bottomLoading
                            ? onBottomTap
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.PrimaryGreen,
                          disabledBackgroundColor:
                              AppColors.PrimaryGreen.withValues(alpha: 0.45),
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 8,
                          shadowColor:
                              AppColors.PrimaryGreen.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: bottomLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                bottomButtonLabel!,
                                style: PgoTextStyles.title(
                                  color: AppColors.SecondBlue,
                                  weight: FontWeight.w900,
                                ).copyWith(fontSize: compact ? 18 : 21),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
    this.title,
    this.dense = false,
  });

  final String? title;
  final List<Widget> children;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: dense ? 20 : 28),
      padding: EdgeInsets.fromLTRB(
        dense ? 20 : 26,
        dense ? 20 : 24,
        dense ? 20 : 26,
        dense ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dense ? 22 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _SectionLabel(title!),
            SizedBox(height: dense ? 14 : 18),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.title,
    required this.color,
    required this.rows,
    required this.values,
    required this.onChanged,
    this.icon,
    this.label,
    this.dense = false,
  });

  final String title;
  final IconData? icon;
  final String? label;
  final Color color;
  final List<_SettingSwitchSpec> rows;
  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      dense: dense,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: dense ? 23 : 27,
              backgroundColor: color,
              child: label != null
                  ? Text(label!,
                      style: PgoTextStyles.title(
                        color: AppColors.SecondBlue,
                        weight: FontWeight.w900,
                      ).copyWith(fontSize: dense ? 14 : 15))
                  : Icon(icon,
                      color: AppColors.SecondBlue, size: dense ? 23 : 27),
            ),
            SizedBox(width: dense ? 12 : 16),
            Text(
              title,
              style: PgoTextStyles.title(
                color: AppColors.SecondBlue,
                weight: FontWeight.w900,
              ).copyWith(fontSize: dense ? 16 : 18),
            ),
          ],
        ),
        SizedBox(height: dense ? 16 : 22),
        for (final row in rows) ...[
          _SettingsSwitchTile(
            row.icon,
            row.title,
            values[row.key] ?? true,
            (value) => onChanged(row.key, value),
            compact: dense,
          ),
        ],
      ],
    );
  }
}

class _SettingSwitchSpec {
  const _SettingSwitchSpec(this.key, this.icon, this.title);

  final String key;
  final IconData icon;
  final String title;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: PgoTextStyles.title(
        color: AppColors.SecondBlue,
        weight: FontWeight.w900,
      ).copyWith(fontSize: 15),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  const _SegmentedSelector({
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 46 : 52,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.SecondBlue.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.SecondBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option,
                  style: PgoTextStyles.title(
                    color: selected ? Colors.white : AppColors.SecondBlue,
                    weight: FontWeight.w800,
                  ).copyWith(fontSize: compact ? 15 : 18),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 50 : 56,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.SecondBlue.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: options
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.SecondBlue, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          item,
                          style: PgoTextStyles.body(
                            color: AppColors.SecondBlue,
                            weight: FontWeight.w700,
                          ).copyWith(fontSize: compact ? 14 : 16),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: compact ? 42 : 48,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : Colors.white,
          border:
              Border.all(color: AppColors.SecondBlue.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: PgoTextStyles.body(
            color: selected ? Colors.white : AppColors.SecondBlue,
            weight: FontWeight.w900,
          ).copyWith(fontSize: compact ? 13 : 14),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.iconBackground = const Color(0xFFD9ECFF),
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconBackground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 20 : 24,
          backgroundColor: iconBackground,
          child:
              Icon(icon, color: AppColors.SecondBlue, size: compact ? 20 : 24),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PgoTextStyles.body(
                  color: AppColors.SecondBlue,
                  weight: FontWeight.w800,
                ).copyWith(fontSize: compact ? 14 : 15),
              ),
              if ((subtitle ?? '').isNotEmpty)
                Text(
                  subtitle!,
                  style: PgoTextStyles.bodySecondary(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
                    weight: FontWeight.w500,
                  ).copyWith(fontSize: compact ? 12 : 13),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF9AC12A),
          inactiveTrackColor: const Color(0xFF788190),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile(this.icon, this.title, this.value, this.onChanged,
      {this.compact = false});

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.SecondBlue, size: compact ? 22 : 26),
            SizedBox(width: compact ? 12 : 18),
            Expanded(
              child: Text(
                title,
                style: PgoTextStyles.body(
                  color: AppColors.SecondBlue,
                  weight: FontWeight.w500,
                ).copyWith(fontSize: compact ? 13.5 : 14.5),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF9AC12A),
              inactiveTrackColor: const Color(0xFF788190),
              onChanged: onChanged,
            ),
          ],
        ),
        const Divider(color: Color(0xFFDDE2E8), height: 1, thickness: 1),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF4B68) : AppColors.SecondBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: PgoTextStyles.body(
                  color: color,
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 14.5),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 36),
          ],
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.valid, required this.text});

  final bool valid;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 18),
      child: Row(
        children: [
          Text(
            valid ? '✓' : 'x',
            style: _titleStyle(
              size: 22,
              color: valid ? const Color(0xFF9AC12A) : const Color(0xFFFF4B68),
            ),
          ),
          const SizedBox(width: 18),
          Text(text, style: _titleStyle(size: 18, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.SecondBlue.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.SecondBlue.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.SecondBlue, width: 1.4),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.SecondBlue, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: _bodyStyle(size: 14, weight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up_rounded,
                  color: AppColors.SecondBlue),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: _bodyStyle(size: 12, height: 1.3)),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFDDE2E8), height: 1),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.SecondBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: _bodyStyle(size: 11.5, height: 1.2))),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider({this.height = 38});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height / 2),
      child: const Divider(color: Color(0xFFDDE2E8), height: 1),
    );
  }
}

void _showDeleteAccountDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => _DangerDialog(
      icon: Icons.delete_outline,
      title: '¿Eliminar cuenta?',
      body:
          'Esta acción eliminará tu perfil, historial y datos asociados a PGO. No podrás deshacerla.',
      primaryLabel: 'Cancelar',
      dangerLabel: 'Eliminar cuenta',
      onDanger: () async {
        await AccountService().deleteAccount();
        await SessionService().clear();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
    ),
  );
}

void showLogoutDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => _DangerDialog(
      icon: Icons.power_settings_new_rounded,
      title: '¿Cerrar sesión?',
      body: 'Tendrás que volver a iniciar sesión para usar PGO',
      primaryLabel: 'Cancelar',
      dangerLabel: 'Cerrar sesión',
      onDanger: () async {
        await SessionService().clear();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
    ),
  );
}

class _DangerDialog extends StatefulWidget {
  const _DangerDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.dangerLabel,
    required this.onDanger,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final String dangerLabel;
  final Future<void> Function() onDanger;

  @override
  State<_DangerDialog> createState() => _DangerDialogState();
}

class _DangerDialogState extends State<_DangerDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: const Color(0xFFFF4B68), size: 92),
            const SizedBox(height: 8),
            Text(widget.title,
                style: _titleStyle(size: 27, weight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(widget.body,
                textAlign: TextAlign.center,
                style: _bodyStyle(size: 17, height: 1.22)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.SecondBlue,
                      side: const BorderSide(
                          color: AppColors.SecondBlue, width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(widget.primaryLabel,
                        style: _bodyStyle(weight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isLoading = true);
                            try {
                              await widget.onDanger();
                            } catch (error) {
                              if (mounted) {
                                setState(() => _isLoading = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4B68),
                      side: const BorderSide(
                          color: Color(0xFFFF4B68), width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.dangerLabel,
                            style: _bodyStyle(
                                weight: FontWeight.w900,
                                color: const Color(0xFFFF4B68))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeSide(String? side) {
  final normalized = (side ?? '').trim().toLowerCase();
  if (normalized.contains('rev')) return 'Revés';
  if (normalized.contains('amb')) return 'Ambos';
  return 'Drive';
}

TextStyle _titleStyle({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.SecondBlue,
}) {
  return PgoTextStyles.title(color: color, weight: weight).copyWith(
    fontSize: size,
  );
}

TextStyle _bodyStyle({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.SecondBlue,
  double height = 1.18,
}) {
  return PgoTextStyles.body(color: color, weight: weight, height: height)
      .copyWith(fontSize: size);
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> openSupportEmail() async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'soporte@pgo.pe',
    query: 'subject=Soporte PGO',
  );
  await launchUrl(uri);
}
