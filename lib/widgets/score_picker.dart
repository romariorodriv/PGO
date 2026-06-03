import 'package:flutter/material.dart';

import '../constants/colors.dart';

int? tournamentScoreLeader(String score) {
  var leftSets = 0;
  var rightSets = 0;
  final sets = score
      .split(',')
      .map((set) => set.trim())
      .where((set) => set.isNotEmpty)
      .toList();
  if (sets.isEmpty) return null;
  for (final set in sets) {
    final parts = set.split('-').map(int.tryParse).toList();
    if (parts.length != 2 || parts[0] == null || parts[1] == null) {
      return null;
    }
    if (parts[0]! > parts[1]!) {
      leftSets++;
    } else if (parts[1]! > parts[0]!) {
      rightSets++;
    }
  }
  if (leftSets == rightSets) return 0;
  return leftSets > rightSets ? 1 : 2;
}

class ScorePicker extends StatefulWidget {
  const ScorePicker({super.key, required this.controller, this.maxSets = 3});

  final TextEditingController controller;
  final int maxSets;

  @override
  State<ScorePicker> createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  int? _setCount;
  late List<List<int>> _sets;

  @override
  void initState() {
    super.initState();
    _sets = _parse(widget.controller.text);
    _setCount = _sets.isEmpty ? null : _sets.length;
    _sync();
  }

  List<List<int>> _parse(String value) {
    final matches = RegExp(r'(\d{1,2})\s*-\s*(\d{1,2})').allMatches(value);
    return matches
        .map((m) => [int.parse(m.group(1)!), int.parse(m.group(2)!)])
        .take(widget.maxSets)
        .toList();
  }

  void _setFinishedSets(int count) {
    setState(() {
      _setCount = count;
      while (_sets.length < count) {
        _sets.add([0, 0]);
      }
      if (_sets.length > count) {
        _sets = _sets.take(count).toList();
      }
      _sync();
    });
  }

  void _sync() {
    if (_setCount == null) {
      widget.controller.text = '';
      return;
    }
    widget.controller.text =
        _sets.take(_setCount!).map((s) => '${s[0]}-${s[1]}').join(', ');
  }

  void _change(int setIndex, int teamIndex, int delta) {
    setState(() {
      _sets[setIndex][teamIndex] =
          (_sets[setIndex][teamIndex] + delta).clamp(0, 20).toInt();
      _sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sets terminados',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= widget.maxSets; i++) ...[
              Expanded(child: _setCountButton(i)),
              if (i < widget.maxSets) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Games por set',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_setCount == null)
          Text(
            'Selecciona cuántos sets terminaron para ingresar los games.',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (var i = 0; i < _setCount!; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'Set ${i + 1}',
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(child: _counter(i, 0)),
                const SizedBox(width: 8),
                Expanded(child: _counter(i, 1)),
              ],
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _setCountButton(int count) {
    final selected = _setCount == count;
    return InkWell(
      onTap: () => _setFinishedSets(count),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FF59) : const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF9DD600)
                : AppColors.SecondBlue.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _counter(int setIndex, int teamIndex) {
    final value = _sets[setIndex][teamIndex];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _step(Icons.remove_rounded, () => _change(setIndex, teamIndex, -1)),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          _step(Icons.add_rounded, () => _change(setIndex, teamIndex, 1)),
        ],
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.SecondBlue),
      ),
    );
  }
}
