import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/dhikr_set.dart';
import '../providers/dhikr_providers.dart';
import '../theme/app_theme.dart';

class AddDhikrScreen extends ConsumerStatefulWidget {
  const AddDhikrScreen({super.key, this.existing});

  /// When set, the screen edits this dhikr instead of creating a new one.
  final DhikrSet? existing;

  @override
  ConsumerState<AddDhikrScreen> createState() => _AddDhikrScreenState();
}

class _AddDhikrScreenState extends ConsumerState<AddDhikrScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _arabicController;
  late final TextEditingController _transliterationController;
  late final TextEditingController _translationController;
  late final TextEditingController _countController;

  late String _colorHex;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _arabicController = TextEditingController(text: existing?.arabic ?? '');
    _transliterationController =
        TextEditingController(text: existing?.transliteration ?? '');
    _translationController =
        TextEditingController(text: existing?.translation ?? '');
    _countController = TextEditingController(
      text: '${existing?.targetCount ?? 33}',
    );
    _colorHex = existing?.colorHex ?? AppTheme.dhikrColorPalette.first;
    if (!AppTheme.dhikrColorPalette.contains(_colorHex)) {
      _colorHex = AppTheme.dhikrColorPalette.first;
    }
  }

  @override
  void dispose() {
    _arabicController.dispose();
    _transliterationController.dispose();
    _translationController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final arabic = _arabicController.text.trim();
      final transliteration = _transliterationController.text.trim();
      final translation = _translationController.text.trim();
      final targetCount = int.parse(_countController.text.trim());

      if (_isEditing) {
        final existing = widget.existing!;
        existing.arabic = arabic;
        existing.transliteration = transliteration;
        existing.translation = translation;
        existing.targetCount = targetCount;
        existing.colorHex = _colorHex;
        await ref.read(dhikrSetsProvider.notifier).update(existing);
      } else {
        final dhikrSet = DhikrSet(
          id: const Uuid().v4(),
          arabic: arabic,
          transliteration: transliteration,
          translation: translation,
          targetCount: targetCount,
          isCustom: true,
          colorHex: _colorHex,
          createdAt: DateTime.now(),
        );
        await ref.read(dhikrSetsProvider.notifier).add(dhikrSet);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null || !existing.isCustom) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text('Delete this dhikr?'),
          content: Text(
            '“${existing.transliteration.isEmpty ? existing.arabic : existing.transliteration}” will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFBF360C)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final activeId = ref.read(activeDhikrIdProvider);
    await ref.read(dhikrSetsProvider.notifier).delete(existing.id);
    if (activeId == existing.id) {
      ref.read(activeDhikrIdProvider.notifier).state = '';
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final canDelete = existing?.isCustom == true;
    final deleteDisabledReason =
        'Built-in dhikr sets cannot be deleted';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit dhikr' : 'Add custom dhikr'),
        actions: [
          if (_isEditing)
            Tooltip(
              message: canDelete
                  ? 'Delete dhikr'
                  : deleteDisabledReason,
              child: IconButton(
                onPressed: canDelete && !_saving ? _confirmDelete : null,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: canDelete
                      ? AppTheme.accentGold
                      : AppTheme.accentGold.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            TextFormField(
              controller: _arabicController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: _decoration('Arabic text', hint: 'سُبْحَانَ اللَّه'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Arabic text is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _transliterationController,
              decoration: _decoration(
                'Transliteration',
                hint: 'Subhanallah',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _translationController,
              decoration: _decoration(
                'Translation (optional)',
                hint: 'Glory be to Allah',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration('Planned count', hint: '33'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Planned count is required';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a positive whole number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppTheme.dhikrColorPalette.map((hex) {
                final selected = hex == _colorHex;
                final color = AppTheme.colorFromHex(hex);
                return InkWell(
                  onTap: () => setState(() => _colorHex = hex),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppTheme.darkGreen
                            : Colors.white.withValues(alpha: 0.8),
                        width: selected ? 3 : 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.lightGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.lightGold,
                      ),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save dhikr'),
            ),
          ],
        ),
      ),
    );
  }
}
