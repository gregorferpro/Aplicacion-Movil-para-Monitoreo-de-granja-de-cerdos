// Models for the Cabana Porcina application.

enum ReproductiveStatus { empty, inHeat, inMating, observation, confirmed }

class BoarRecord {
  const BoarRecord({
    required this.number,
    required this.name,
    required this.bloodline,
  });

  final int number;
  final String name;
  final String bloodline;

  bool get isRegistered => name.trim().isNotEmpty;

  String get label {
    final cleanBloodline = bloodline.trim();
    if (cleanBloodline.isEmpty) {
      return name.trim();
    }
    return '${name.trim()} · $cleanBloodline';
  }

  BoarRecord copyWith({String? name, String? bloodline}) {
    return BoarRecord(
      number: number,
      name: name ?? this.name,
      bloodline: bloodline ?? this.bloodline,
    );
  }

  BoarRecord cleared() {
    return BoarRecord(number: number, name: '', bloodline: '');
  }
}

class FarrowingRecord {
  const FarrowingRecord({
    required this.date,
    required this.bornAlive,
    required this.dead,
    required this.males,
    required this.females,
    required this.mummified,
    required this.notes,
  });

  final DateTime date;
  final int bornAlive;
  final int dead;
  final int males;
  final int females;
  final int mummified;
  final String notes;

  int get totalBorn => bornAlive + dead + mummified;

  String get summary {
    return '$totalBorn nacidos · $bornAlive vivos · $dead muertos';
  }
}

class AbortionRecord {
  const AbortionRecord({
    required this.date,
    required this.lostCount,
    required this.gestationDays,
    required this.notes,
  });

  final DateTime date;
  final int lostCount;
  final int gestationDays;
  final String notes;

  String get summary {
    return 'Aborto · $lostCount perdidos · $gestationDays días';
  }
}

class GestationCrate {
  const GestationCrate({
    required this.number,
    required this.side,
    required this.sideNumber,
    required this.earTag,
    required this.matingDates,
    required this.matingBoars,
    required this.farrowingRecord,
    required this.abortionRecord,
    required this.heatCheckDone,
  });

  final int number;
  final String side;
  final int sideNumber;
  final String? earTag;
  final List<DateTime> matingDates;
  final List<String?> matingBoars;
  final FarrowingRecord? farrowingRecord;
  final AbortionRecord? abortionRecord;
  final bool heatCheckDone;

  bool get isOccupied => earTag != null;

  ReproductiveStatus get status {
    if (!isOccupied) {
      return ReproductiveStatus.empty;
    }
    if (matingDates.isEmpty) {
      return ReproductiveStatus.inHeat;
    }
    if (matingDates.length < 3) {
      return ReproductiveStatus.inMating;
    }
    final days = daysPregnant ?? 0;
    if (days < 21 || !heatCheckDone) {
      return ReproductiveStatus.observation;
    }
    return ReproductiveStatus.confirmed;
  }

  bool get needsHeatCheck {
    final days = daysPregnant;
    return isOccupied &&
        matingDates.length >= 3 &&
        days != null &&
        days >= 21 &&
        !heatCheckDone;
  }

  String get statusLabel {
    return switch (status) {
      ReproductiveStatus.empty => 'Libre',
      ReproductiveStatus.inHeat => 'En celo',
      ReproductiveStatus.inMating => 'En monta',
      ReproductiveStatus.observation => 'Observación',
      ReproductiveStatus.confirmed => 'Confirmada',
    };
  }

  DateTime? get gestationStartDate {
    if (matingDates.length < 3) {
      return null;
    }
    return _dateOnly(matingDates[2]);
  }

  int? get daysPregnant {
    final start = gestationStartDate;
    if (start == null) {
      return null;
    }
    return _dateOnly(DateTime.now()).difference(start).inDays;
  }

  DateTime? get expectedFarrowingDate {
    final start = gestationStartDate;
    if (start == null) {
      return null;
    }
    return start.add(const Duration(days: 115));
  }

  DateTime? get transferToMaternityDate {
    final farrowing = expectedFarrowingDate;
    if (farrowing == null) {
      return null;
    }
    return farrowing.subtract(const Duration(days: 7));
  }

  String get gestationSummary {
    final abortion = abortionRecord;
    if (abortion != null) {
      return abortion.summary;
    }
    final farrowing = farrowingRecord;
    if (farrowing != null) {
      return farrowing.summary;
    }
    return switch (status) {
      ReproductiveStatus.empty => 'Sin registro',
      ReproductiveStatus.inHeat => 'En celo · lista para montar',
      ReproductiveStatus.inMating => 'En monta · ${matingDates.length}/3',
      ReproductiveStatus.observation =>
        '${daysPregnant ?? 0} días · observación',
      ReproductiveStatus.confirmed => '${daysPregnant ?? 0} días · confirmado',
    };
  }

  String get transferSummary {
    if (status != ReproductiveStatus.confirmed &&
        status != ReproductiveStatus.observation) {
      return statusLabel;
    }
    return 'traslado ${_formatDate(transferToMaternityDate)}';
  }

  GestationCrate copyWith({
    int? number,
    String? side,
    int? sideNumber,
    Object? earTag = _unset,
    Object? matingDates = _unset,
    Object? matingBoars = _unset,
    Object? farrowingRecord = _unset,
    Object? abortionRecord = _unset,
    bool? heatCheckDone,
  }) {
    return GestationCrate(
      number: number ?? this.number,
      side: side ?? this.side,
      sideNumber: sideNumber ?? this.sideNumber,
      earTag: earTag == _unset ? this.earTag : earTag as String?,
      matingDates: matingDates == _unset
          ? this.matingDates
          : matingDates as List<DateTime>,
      matingBoars: matingBoars == _unset
          ? this.matingBoars
          : matingBoars as List<String?>,
      farrowingRecord: farrowingRecord == _unset
          ? this.farrowingRecord
          : farrowingRecord as FarrowingRecord?,
      abortionRecord: abortionRecord == _unset
          ? this.abortionRecord
          : abortionRecord as AbortionRecord?,
      heatCheckDone: heatCheckDone ?? this.heatCheckDone,
    );
  }
}

const Object _unset = Object();

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
