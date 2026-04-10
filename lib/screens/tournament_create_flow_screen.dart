import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_description_screen.dart';

enum _TournamentCreateStep {
  intro,
  basic,
  schedule,
  settings,
  review,
  published
}

class TournamentCreateFlowScreen extends StatefulWidget {
  const TournamentCreateFlowScreen({
    super.key,
    this.initialTournament,
  });

  final TournamentRecord? initialTournament;

  @override
  State<TournamentCreateFlowScreen> createState() =>
      _TournamentCreateFlowScreenState();
}

class _TournamentCreateFlowScreenState
    extends State<TournamentCreateFlowScreen> {
  static const int _maxTournamentPhotoBytes = 850 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController =
      TextEditingController(text: 'Torneo PGO');
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _clubController =
      TextEditingController(text: 'One Padel Olguin');
  final TextEditingController _addressController =
      TextEditingController(text: 'Av. Manuel Olguin 325');
  final TextEditingController _districtController =
      TextEditingController(text: 'Santiago de Surco');
  final TextEditingController _slotsController =
      TextEditingController(text: '12');
  final TextEditingController _descriptionController = TextEditingController(
      text: 'Torneo de la comunidad "Pepito" amistoso...');
  final TextEditingController _costController =
      TextEditingController(text: 'S/. 50 x persona');
  final TextEditingController _prizeController =
      TextEditingController(text: '1 turno gratis');

  _TournamentCreateStep _step = _TournamentCreateStep.intro;
  String _tournamentType = 'Americano';
  String _category = '4TA';
  String _modality = 'Masculino';
  String _city = 'Lima';
  String _format = 'Dobles';
  bool _isSubmitting = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoDataUrl;
  TournamentRecord? _createdTournament;

  String get _displayTitle => _createdTournament?.title ?? _nameController.text;
  String get _displayLocation =>
      _createdTournament?.location ?? _clubController.text;
  String get _displayPrize =>
      _createdTournament?.prize ?? _prizeController.text;
  int get _displayEntryFee => _createdTournament?.entryFee ?? _parseEntryFee();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
    final initialTournament = widget.initialTournament;
    if (initialTournament != null) {
      _hydrateFromTournament(initialTournament);
      _createdTournament = initialTournament;
      _step = _TournamentCreateStep.review;
    } else {
      final now = DateTime.now().add(const Duration(days: 7));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = const TimeOfDay(hour: 21, minute: 30);
    }
    _syncDateTimeControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _clubController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _slotsController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  void _syncDateTimeControllers() {
    if (_selectedDate != null) {
      final formatted = DateFormat('EEEE d MMM', 'es').format(_selectedDate!);
      _dateController.text = formatted.replaceFirstMapped(
        RegExp(r'^\\w'),
        (match) => match.group(0)!.toUpperCase(),
      );
    }
    if (_selectedTime != null) {
      final hour = _selectedTime!.hour.toString().padLeft(2, '0');
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$minute';
    }
  }

  void _hydrateFromTournament(TournamentRecord tournament) {
    _nameController.text = tournament.title;
    _clubController.text = tournament.location;
    _addressController.text = tournament.address ?? '';
    _districtController.text = tournament.district;
    _slotsController.text = '${tournament.playerCapacity}';
    _descriptionController.text = tournament.description ?? '';
    _costController.text = 'S/. ${tournament.entryFee} x persona';
    _prizeController.text = tournament.prize;
    _tournamentType = tournament.tournamentType;
    _category = tournament.category;
    _modality = tournament.modality;
    _city = tournament.city;
    _format = tournament.format;
    _selectedDate = DateTime(
      tournament.startsAt.year,
      tournament.startsAt.month,
      tournament.startsAt.day,
    );
    _selectedTime = TimeOfDay(
      hour: tournament.startsAt.hour,
      minute: tournament.startsAt.minute,
    );
    _selectedPhotoDataUrl = tournament.photoUrl;
    _selectedPhotoBytes = tryDecodeDataUrl(tournament.photoUrl);
  }

  void _next() {
    setState(() {
      _step = switch (_step) {
        _TournamentCreateStep.intro => _TournamentCreateStep.basic,
        _TournamentCreateStep.basic => _TournamentCreateStep.schedule,
        _TournamentCreateStep.schedule => _TournamentCreateStep.settings,
        _TournamentCreateStep.settings => _TournamentCreateStep.review,
        _TournamentCreateStep.review => _TournamentCreateStep.published,
        _TournamentCreateStep.published => _TournamentCreateStep.published,
      };
    });
  }

  void _back() {
    if (_step == _TournamentCreateStep.intro) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _step = switch (_step) {
        _TournamentCreateStep.intro => _TournamentCreateStep.intro,
        _TournamentCreateStep.basic => _TournamentCreateStep.intro,
        _TournamentCreateStep.schedule => _TournamentCreateStep.basic,
        _TournamentCreateStep.settings => _TournamentCreateStep.schedule,
        _TournamentCreateStep.review => _TournamentCreateStep.settings,
        _TournamentCreateStep.published => _TournamentCreateStep.review,
      };
    });
  }

  int _parseEntryFee() {
    final digits = _costController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits) ?? 0;
    return parsed.clamp(0, 999999);
  }

  int _parsePlayerCapacity() {
    final digits = _slotsController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits) ?? 0;
    return parsed.clamp(0, 999);
  }

  DateTime _buildStartsAt() {
    if (_selectedDate == null || _selectedTime == null) {
      return DateTime.now();
    }

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.SecondBlue,
              secondary: AppColors.PrimaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _syncDateTimeControllers();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 21, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.SecondBlue,
              secondary: AppColors.PrimaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
      _syncDateTimeControllers();
    });
  }

  Future<void> _pickTournamentPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 960,
      maxHeight: 960,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxTournamentPhotoBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La imagen sigue siendo muy grande. Prueba con una foto mas ligera o recortada.',
          ),
        ),
      );
      return;
    }
    final mimeType =
        picked.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _openDistrictInMaps() async {
    final query = [
      _districtController.text.trim(),
      _city.trim(),
      _clubController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query.isEmpty ? 'padel lima' : query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir Google Maps en este dispositivo.'),
        ),
      );
    }
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case _TournamentCreateStep.basic:
        if (_nameController.text.trim().isEmpty) {
          _showValidation('Ingresa el nombre del torneo.');
          return false;
        }
        return true;
      case _TournamentCreateStep.schedule:
        if (_selectedDate == null ||
            _selectedTime == null ||
            _clubController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty ||
            _districtController.text.trim().isEmpty) {
          _showValidation('Completa fecha, hora, sede y distrito.');
          return false;
        }
        return true;
      case _TournamentCreateStep.settings:
        if (_parsePlayerCapacity() < 4) {
          _showValidation('Los cupos deben ser al menos 4.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _handleNextStep() {
    if (!_validateCurrentStep()) return;
    _next();
  }

  Future<void> _submitTournament(String status) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = TournamentService();
      final tournament = _createdTournament == null
          ? await service.createTournament(
              title: _nameController.text,
              tournamentType: _tournamentType,
              playerCapacity: _parsePlayerCapacity(),
              modality: _modality,
              format: _format,
              location: _clubController.text,
              address: _addressController.text,
              city: _city,
              district: _districtController.text,
              startsAt: _buildStartsAt(),
              prize: _prizeController.text,
              entryFee: _parseEntryFee(),
              category: _category,
              description: _descriptionController.text,
              photoUrl: _selectedPhotoDataUrl,
              status: status,
            )
          : await service.updateTournament(
              tournamentId: _createdTournament!.id,
              title: _nameController.text,
              tournamentType: _tournamentType,
              playerCapacity: _parsePlayerCapacity(),
              modality: _modality,
              format: _format,
              location: _clubController.text,
              address: _addressController.text,
              city: _city,
              district: _districtController.text,
              startsAt: _buildStartsAt(),
              prize: _prizeController.text,
              entryFee: _parseEntryFee(),
              category: _category,
              description: _descriptionController.text,
              photoUrl: _selectedPhotoDataUrl,
              status: status,
            );

      if (!mounted) return;
      setState(() {
        _createdTournament = tournament;
        _step = status == 'DRAFT'
            ? _TournamentCreateStep.review
            : _TournamentCreateStep.published;
      });

      if (status == 'DRAFT') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrador guardado correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == _TournamentCreateStep.published
        ? 'Torneo publicado'
        : 'Crear torneo';

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _back,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [PgoOptionsMenuButton()],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          child: switch (_step) {
            _TournamentCreateStep.intro => _buildIntro(),
            _TournamentCreateStep.basic => _buildBasic(),
            _TournamentCreateStep.schedule => _buildSchedule(),
            _TournamentCreateStep.settings => _buildSettings(),
            _TournamentCreateStep.review => _buildReview(),
            _TournamentCreateStep.published => _buildPublished(context),
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Center(
        child: _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crea tu torneo en pocos pasos',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              const _IntroStep(text: '1. Define tipo y categoria'),
              const _IntroStep(text: '2. Agrega fecha, hora y sede'),
              const _IntroStep(text: '3. Configura inscripciones'),
              const _IntroStep(text: '4. Revisa y publica'),
              const SizedBox(height: 24),
              _PrimaryActionButton(label: 'Empezar', onTap: _handleNextStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasic() {
    return _StepScaffold(
      currentStep: 1,
      title: 'Informacion basica',
      card: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(label: 'Nombre del torneo'),
            _TextFieldBox(
              controller: _nameController,
              hintText: 'Ej. Torneo Pgo',
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Tipo de torneo'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Americano',
                    selected: _tournamentType == 'Americano',
                    onTap: () => setState(() => _tournamentType = 'Americano'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentButton(
                    label: 'Rey de la cancha',
                    selected: _tournamentType == 'Rey de la cancha',
                    onTap: () =>
                        setState(() => _tournamentType = 'Rey de la cancha'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Categoria'),
            _DropdownBox(
              value: _category,
              items: const ['1RA', '2DA', '3RA', '4TA', '5TA', '6TA'],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Modalidad'),
            _DropdownBox(
              value: _modality,
              items: const ['Masculino', 'Femenino', 'Mixto'],
              onChanged: (value) => setState(() => _modality = value!),
            ),
          ],
        ),
      ),
      onNext: _handleNextStep,
      onBack: _back,
    );
  }

  Widget _buildSchedule() {
    return _StepScaffold(
      currentStep: 2,
      title: 'Fecha y lugar',
      card: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(label: 'Fecha'),
            _TextFieldBox(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.SecondBlue,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Hora'),
            _TextFieldBox(
              controller: _timeController,
              readOnly: true,
              onTap: _pickTime,
              suffixIcon: const Icon(
                Icons.access_time_rounded,
                color: AppColors.SecondBlue,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Club/Sede'),
            _TextFieldBox(controller: _clubController),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Direccion'),
            _TextFieldBox(controller: _addressController),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Ciudad'),
            _DropdownBox(
              value: _city,
              items: const ['Lima', 'Trujillo', 'Arequipa'],
              onChanged: (value) => setState(() => _city = value!),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Distrito'),
            _TextFieldBox(
              controller: _districtController,
              hintText: 'Ej. Santiago de Surco',
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.map_rounded,
                  color: AppColors.SecondBlue,
                ),
                onPressed: _openDistrictInMaps,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openDistrictInMaps,
                icon: const Icon(Icons.near_me_rounded, size: 16),
                label: const Text('Ver distrito en Google Maps'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.SecondBlue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
      onNext: _handleNextStep,
      onBack: _back,
    );
  }

  Widget _buildSettings() {
    return _StepScaffold(
      currentStep: 3,
      title: 'Configuracion',
      card: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(label: 'Cupos'),
            _TextFieldBox(
              controller: _slotsController,
              hintText: 'Ej. 12',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Formato del torneo'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Singles',
                    selected: _format == 'Singles',
                    onTap: () => setState(() => _format = 'Singles'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentButton(
                    label: 'Dobles',
                    selected: _format == 'Dobles',
                    onTap: () => setState(() => _format = 'Dobles'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Descripcion', suffix: ' (opcional)'),
            _TextFieldBox(controller: _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Costo de inscripcion'),
            _TextFieldBox(controller: _costController),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Premio'),
            _TextFieldBox(controller: _prizeController),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFD8DEE7),
            ),
            const SizedBox(height: 14),
            const _FieldLabel(label: 'Foto del torneo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTournamentPhoto,
              child: Container(
                width: double.infinity,
                height: 138,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EBF0),
                  borderRadius: BorderRadius.circular(18),
                  image: _selectedPhotoBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_selectedPhotoBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedPhotoBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.gray,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Subir portada',
                            style: TextStyle(
                              color: AppColors.SecondBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Se mostrara en la ficha del torneo',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Cambiar foto',
                                style: TextStyle(
                                  color: AppColors.SecondBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPhotoBytes = null;
                                  _selectedPhotoDataUrl = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'Eliminar foto',
                                  style: TextStyle(
                                    color: Color(0xFFC13A3A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      onNext: _handleNextStep,
      onBack: _back,
    );
  }

  Widget _buildReview() {
    return _StepScaffold(
      currentStep: 4,
      title: 'Revisa tu torneo',
      growCard: false,
      card: Column(
        children: [
          _ReviewHeroCard(
            title: _displayTitle,
            subtitle: '${_dateController.text} · ${_timeController.text}',
            club: _displayLocation,
            photoUrl: _createdTournament?.photoUrl ?? _selectedPhotoDataUrl,
          ),
          const SizedBox(height: 18),
          _ReviewSectionCard(
            title: 'Informacion basica',
            onTap: () => setState(() => _step = _TournamentCreateStep.basic),
            lines: [
              'Tipo: $_tournamentType',
              'Categoria: ${_category.toLowerCase()}',
              'Modalidad: $_modality',
            ],
          ),
          const SizedBox(height: 14),
          _ReviewSectionCard(
            title: 'Configuracion',
            onTap: () => setState(() => _step = _TournamentCreateStep.settings),
            lines: [
              'Cupos: ${_slotsController.text}',
              'Tipo de inscripcion: ${_format.toLowerCase()}',
              'Costo de inscripcion: S/. $_displayEntryFee x persona',
              'Premio: $_displayPrize',
              'Distrito: ${_districtController.text}',
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Al publicar, las inscripciones se abriran automaticamente',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onNext: _handleNextStep,
      onBack: () => _submitTournament('DRAFT'),
      nextLabel: 'Publicar',
      backLabel: 'Guardar',
      nextAction: () => _submitTournament('PUBLISHED'),
      isSubmitting: _isSubmitting,
    );
  }

  Widget _buildPublished(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: Color(0xFFD7FF59),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Torneo publicado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu torneo ya esta visible y las inscripciones\nestan abiertas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _WhiteCard(
            child: Column(
              children: [
                _ReviewHeroCard(
                  title: _displayTitle,
                  subtitle: '${_dateController.text} · ${_timeController.text}',
                  club: _displayLocation,
                  badge: 'Inscripciones abiertas',
                  compact: true,
                  photoUrl:
                      _createdTournament?.photoUrl ?? _selectedPhotoDataUrl,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFD8DEE7),
                ),
                const SizedBox(height: 18),
                _PrimaryActionButton(
                  label: 'Ver torneo',
                  enabled: !_isSubmitting,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TournamentDescriptionScreen(
                          tournament: _createdTournament,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const _SecondaryActionButton(label: 'Compartir'),
                const SizedBox(height: 10),
                _SecondaryActionButton(
                  label: 'Ir a mis torneos',
                  enabled: !_isSubmitting,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.currentStep,
    required this.title,
    required this.card,
    required this.onNext,
    required this.onBack,
    this.nextLabel = 'Continuar',
    this.backLabel = 'Atras',
    this.growCard = true,
    this.nextAction,
    this.isSubmitting = false,
  });

  final int currentStep;
  final String title;
  final Widget card;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextLabel;
  final String backLabel;
  final bool growCard;
  final VoidCallback? nextAction;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          Text(
            'Paso $currentStep de 4',
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _ProgressIndicatorRow(currentStep: currentStep),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          card,
          const SizedBox(height: 18),
          _ActionRow(
            backLabel: backLabel,
            nextLabel: nextLabel,
            onBack: onBack,
            onNext: nextAction ?? onNext,
            isSubmitting: isSubmitting,
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicatorRow extends StatelessWidget {
  const _ProgressIndicatorRow({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        if (index.isOdd) {
          final lineStep = (index ~/ 2) + 1;
          final active = lineStep < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: active
                  ? AppColors.SecondBlue
                  : AppColors.SecondBlue.withValues(alpha: 0.38),
            ),
          );
        }

        final dotStep = (index ~/ 2) + 1;
        final active = dotStep <= currentStep;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: active
                ? AppColors.SecondBlue
                : AppColors.SecondBlue.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.suffix});

  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : const Color(0xFFE8EBF0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppColors.SecondBlue.withValues(alpha: 0.65),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.isSubmitting = false,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SecondaryActionButton(
              label: backLabel,
              onTap: isSubmitting ? null : onBack,
              enabled: !isSubmitting,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PrimaryActionButton(
              label: nextLabel,
              onTap: isSubmitting ? null : onNext,
              enabled: !isSubmitting,
              loading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD7FF59),
          foregroundColor: AppColors.SecondBlue,
          disabledBackgroundColor:
              const Color(0xFFD7FF59).withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.SecondBlue.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: label.length > 12 ? 14 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5E8EE),
          foregroundColor: AppColors.SecondBlue,
          disabledBackgroundColor:
              const Color(0xFFE5E8EE).withValues(alpha: 0.7),
          disabledForegroundColor: AppColors.SecondBlue.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: label.length > 12 ? 13 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReviewHeroCard extends StatelessWidget {
  const _ReviewHeroCard({
    required this.title,
    required this.subtitle,
    required this.club,
    this.photoUrl,
    this.badge,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String club;
  final String? photoUrl;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedPhoto = photoUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: compact ? 180 : 172,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (normalizedPhoto != null && normalizedPhoto.isNotEmpty)
              normalizedPhoto.startsWith('http')
                  ? Image.network(
                      normalizedPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/InkaPadel.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : (tryDecodeDataUrl(normalizedPhoto) != null
                      ? Image.memory(
                          tryDecodeDataUrl(normalizedPhoto)!,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/InkaPadel.png',
                          fit: BoxFit.cover,
                        ))
            else
              Image.asset(
                'assets/images/InkaPadel.png',
                fit: BoxFit.cover,
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xD61C2A3A),
                    Color(0x661C2A3A),
                    Color(0x221C2A3A),
                  ],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.whatshot,
                        size: 12,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    club,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({
    required this.title,
    required this.lines,
    this.onTap,
  });

  final String title;
  final List<String> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Editar',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.SecondBlue,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFD8DEE7),
                ),
                const SizedBox(height: 10),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
