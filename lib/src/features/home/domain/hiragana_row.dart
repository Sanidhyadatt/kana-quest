class HiraganaRow {
  const HiraganaRow({
    required this.row,
    required this.label,
    required this.kana,
    required this.focus,
  });

  final int row;
  final String label;
  final String kana;
  final String focus;

  factory HiraganaRow.fromJson(Map<String, dynamic> json) {
    return HiraganaRow(
      row: (json['row'] as num).toInt(),
      label: json['label'] as String,
      kana: json['kana'] as String,
      focus: json['focus'] as String,
    );
  }
}
