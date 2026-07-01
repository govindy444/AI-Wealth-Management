import 'package:equatable/equatable.dart';


class Explanation extends Equatable {
  const Explanation({
    required this.summary,
    this.reasons = const [],
    this.risks = const [],
    this.benefits = const [],
    this.alternatives = const [],
    this.citations = const [],
    this.confidence = 0.0,
  });

  final String summary;

  final List<String> reasons;

  final List<String> risks;

  final List<String> benefits;

  final List<String> alternatives;

  final List<String> citations;

  final double confidence;

  int get confidencePercent => (confidence.clamp(0.0, 1.0) * 100).round();

  
  factory Explanation.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List?)?.map((e) => e.toString()).toList() ?? const [];
    return Explanation(
      summary: (json['summary'] as String?) ?? '',
      reasons: strings('reasons'),
      risks: strings('risks'),
      benefits: strings('benefits'),
      alternatives: strings('alternatives'),
      citations: strings('citations'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props =>
      [summary, reasons, risks, benefits, alternatives, citations, confidence];
}
