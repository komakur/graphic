import 'package:graphic/src/dataflow/tuple.dart';

import 'discrete.dart';

/// The specification of a ordinal scale.
///
/// It converts [String] to [int]s of natural number in order.
class OrdinalScale extends DiscreteScale<String> {
  OrdinalScale({
    List<String>? values,
    bool? inflate,
    double? align,
    String? title,
    String? Function(String, List<double>? visibleRange)? formatter,
    List<String>? ticks,
    int? tickCount,
  }) : super(
          values: values,
          inflate: inflate,
          align: align,
          title: title,
          formatter: formatter,
          ticks: ticks,
          tickCount: tickCount,
        );

  @override
  bool operator ==(Object other) => other is OrdinalScale && super == other;
}

/// The ordinal scale converter.
class OrdinalScaleConv extends DiscreteScaleConv<String, OrdinalScale> {
  OrdinalScaleConv(
    OrdinalScale spec,
    List<Tuple> tuples,
    String variable,
  ) : super(spec, tuples, variable);

  @override
  String defaultFormatter(String value, List<double>? visibleRange) => value;

  @override
  bool operator ==(Object other) => other is OrdinalScaleConv && super == other;
}
