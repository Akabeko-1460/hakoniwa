// あたらしい ハコニワ（子ども）をつくる — 3D空間の生成につながる入口
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme.dart';
import 'tap_scale.dart';

/// 作成されたら (名まえ, ねんれい, 部屋のいろ) を返す。やめたら null。
Future<({String name, int? age, String tone})?> showAddChildDialog(BuildContext context) =>
    showDialog<({String name, int? age, String tone})>(
      context: context,
      barrierColor: AppColors.textStrong.withValues(alpha: 0.35),
      builder: (_) => const _AddChildDialog(),
    );

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  String _tone = kTones.first;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppFonts.maru(15, color: AppColors.textFaint4),
    filled: true,
    fillColor: AppColors.cream,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 5),
    child: Text(
      text,
      style: AppFonts.kaku(11, weight: FontWeight.w600, color: AppColors.textFaint2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final canCreate = _name.text.trim().isNotEmpty;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'あたらしい ハコニワ',
              textAlign: TextAlign.center,
              style: AppFonts.maru(18, weight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'お部屋（3D空間）が じどうで つくられます',
              textAlign: TextAlign.center,
              style: AppFonts.kaku(11, color: AppColors.textFaint2),
            ),
            _label('おなまえ'),
            TextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              cursorColor: AppColors.accent,
              style: AppFonts.maru(15),
              decoration: _decoration('たとえば はると'),
            ),
            _label('ねんれい'),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              cursorColor: AppColors.accent,
              style: AppFonts.maru(15),
              decoration: _decoration('たとえば 4'),
            ),
            _label('お部屋のいろ'),
            Row(
              children: [
                for (final tone in kTones)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TapScale(
                      onTap: () => setState(() => _tone = tone),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: hexColor(tone),
                          shape: BoxShape.circle,
                          border: _tone == tone
                              ? Border.all(color: AppColors.textStrong, width: 3)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: canCreate ? 1 : 0.45,
              child: TapScale(
                onTap: canCreate
                    ? () => Navigator.of(context).pop((
                        name: _name.text.trim(),
                        age: int.tryParse(_age.text),
                        tone: _tone,
                      ))
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadii.small,
                  ),
                  child: Center(
                    child: Text('ハコニワを つくる', style: AppFonts.maru(15, color: Colors.white)),
                  ),
                ),
              ),
            ),
            TapScale(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'やめる',
                    style: AppFonts.kaku(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.textFaint2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
