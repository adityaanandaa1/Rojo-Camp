// lib/l10n/id_material_localizations.dart
// Terjemahan Material bahasa Indonesia bawaan Flutter, dengan dua pengecualian:
// judul besar date picker memakai nama hari lengkap ("Rabu, 21 Okt", bukan
// "Rab, 21 Okt"), dan tombol OK ditulis "Oke" (bawaan Flutter: "OKE").

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class IdMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const IdMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'id';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    await initializeDateFormatting('id');
    return _IdMaterialLocalizations(
      fullYearFormat: DateFormat.y('id'),
      compactDateFormat: DateFormat.yMd('id'),
      shortDateFormat: DateFormat.yMMMd('id'),
      mediumDateFormat: DateFormat('EEEE, d MMM', 'id'),
      longDateFormat: DateFormat.yMMMMEEEEd('id'),
      yearMonthFormat: DateFormat.yMMMM('id'),
      shortMonthDayFormat: DateFormat.MMMd('id'),
      decimalFormat: NumberFormat.decimalPattern('id'),
      twoDigitZeroPaddedFormat: NumberFormat('00', 'id'),
    );
  }

  @override
  bool shouldReload(IdMaterialLocalizationsDelegate old) => false;
}

class _IdMaterialLocalizations extends MaterialLocalizationId {
  const _IdMaterialLocalizations({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  @override
  String get okButtonLabel => 'Oke';
}
