import 'package:corigge/utils/utils.dart';

class PythonCircleIdentificationParams {
  double? circleSize;
  double circlePrecisionPercent;
  double param2;
  double inverseRatioAccumulatorResolution;
  double darknessThreshold;
  bool useFallbackMethod;

  PythonCircleIdentificationParams({
    this.circleSize,
    this.circlePrecisionPercent = 0.33,
    this.param2 = 22,
    this.inverseRatioAccumulatorResolution = 1.32,
    this.darknessThreshold = 0.66,
    this.useFallbackMethod = true,
  });

  factory PythonCircleIdentificationParams.fromJson(Map<String, dynamic> json) {
    return PythonCircleIdentificationParams(
      circleSize: json['circle_size'],
      circlePrecisionPercent: json['circle_precision_percentage'] ?? 0.33,
      darknessThreshold: json['darkness_threshold'] ?? 0.66,
      param2: json['param2'] ?? 22,
      inverseRatioAccumulatorResolution:
          json['inverse_ratio_accumulator_resolution'] ?? 1.32,
      useFallbackMethod: json['use_fallback_method'] ?? false,
    );
  }

  static Map<String, String> getDescriptionForParams() {
    return {
      'circle_precision_percentage':
          'Nível de precisão do círculo, quanto menor, círculos menos circulares são aceitos.',
      'param2':
          'Quanto maior, normalmente, menos círculos são detectados com maior probabilidade de estarem certo.',
      'inverse_ratio_accumulator_resolution':
          'Razão inversa da resolução do acumulador para a resolução da imagem. Por exemplo, se dp=1, o acumulador tem a mesma resolução que a imagem de entrada. Se dp=2, o acumulador tem metade da largura e altura',
      'darkness_threshold':
          'Define o quão escuro um pixel deve ser para ser considerado preto. Quanto menor, mais escuro é considerado preto.'
    };
  }

  static Map<String, String> getNameForParams() {
    return {
      'circle_precision_percentage': 'Precisão do Círculo',
      'param2': 'Param 2',
      'inverse_ratio_accumulator_resolution':
          'Razão de Resolução do Acumulador',
      'darkness_threshold': 'Limiar de Escuro'
    };
  }

  static Map<String, MinMaxPair<double>> getMinMaxForParams() {
    return {
      'circle_precision_percentage': MinMaxPair<double>(0, 2),
      'param2': MinMaxPair<double>(0, 100),
      'inverse_ratio_accumulator_resolution': MinMaxPair<double>(0, 6),
      'darkness_threshold': MinMaxPair<double>(0, 1)
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'use_fallback_method': useFallbackMethod,
      'circle_size': circleSize,
      'circle_precision_percentage': circlePrecisionPercent,
      'param2': param2,
      'inverse_ratio_accumulator_resolution': inverseRatioAccumulatorResolution,
      'darkness_threshold': darknessThreshold,
    };
  }

  // copy with new values

  PythonCircleIdentificationParams copyWith({
    double? circleSize,
    double? circlePrecisionPercent,
    double? param2,
    double? inverseRatioAccumulatorResolution,
    double? darknessThreshold,
    bool? useFallbackMethod,
  }) {
    return PythonCircleIdentificationParams(
      circleSize: circleSize ?? this.circleSize,
      circlePrecisionPercent:
          circlePrecisionPercent ?? this.circlePrecisionPercent,
      param2: param2 ?? this.param2,
      inverseRatioAccumulatorResolution: inverseRatioAccumulatorResolution ??
          this.inverseRatioAccumulatorResolution,
      darknessThreshold: darknessThreshold ?? this.darknessThreshold,
      useFallbackMethod: useFallbackMethod ?? this.useFallbackMethod,
    );
  }
}
