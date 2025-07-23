import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import 'main.dart';

class Page {
  Page(String route) {
    final endPoint = route.split('/').last;
    name = endPoint;
    this.endPoint = endPoint;
  }

  late String name;
  late String endPoint;
}

class PageCard extends StatelessWidget {
  const PageCard({
    required Key key,
    required this.package,
    required this.onPressed,
  }) : super(key: key);

  final Page package;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = theme.textTheme.titleLarge!;
    final TextStyle descriptionStyle = theme.textTheme.bodyMedium!;

    return Container(
        padding: const EdgeInsets.all(4.0),
        child: GestureDetector(
          onTap: () {
            onPressed(package.endPoint);
          },
          child: Card(
              child: DefaultTextStyle(
            maxLines: 3,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: descriptionStyle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                    child: Text(
                      package.name,
                      style: titleStyle,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final data = <(DateTime, double)>[
    (DateTime(2025, 1, 1), 1240),
    (DateTime(2025, 1, 2), 1000),
    (DateTime(2025, 1, 3), 990),
    (DateTime(2025, 1, 4), 1100),
    (DateTime(2025, 1, 5), 1569),
    (DateTime(2025, 1, 6), 2001),
    (DateTime(2025, 1, 7), 799),
    (DateTime(2025, 1, 8), 459),
    (DateTime(2025, 1, 9), 600),
    (DateTime(2025, 1, 10), 1600),
    (DateTime(2025, 1, 11), 1209),
  ];

  final StreamController<Map<String, Set<int>>?> _selectionStream =
      StreamController.broadcast();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _selectionStream.add({
      'hover': {data.length - 1}
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = routes.keys.toList().sublist(1).map((route) => Page(route));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphic Examples'),
      ),
      body: ListView(
        children: [
          ...pages
              .map((package) => (PageCard(
                    key: Key(package.name),
                    package: package,
                    onPressed: (String endPoint) {
                      Navigator.pushNamed(context, '/examples/$endPoint');
                    },
                  )))
              .toList(),
          StreamBuilder(
              stream: _selectionStream.stream,
              initialData: {
                'hover': {data.length - 1}
              },
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                print(snapshot.data?.keys);

                final selectedDataIndex = snapshot.data?['hover']?.firstOrNull;

                if (selectedDataIndex == null) return const SizedBox.shrink();

                final selectedEntry = data[selectedDataIndex];

                return ListTile(
                  leading: const SizedBox(
                    width: 20,
                    height: double.infinity,
                    child: ColoredBox(color: Colors.lightBlue),
                  ),
                  title: const Text('Line №1'),
                  subtitle: Column(
                    spacing: 4,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${selectedEntry.$1}'),
                      Text('Value: ${selectedEntry.$2}'),
                    ],
                  ),
                );
              }),
          SizedBox(
            height: 600,
            child: Chart<(DateTime, double)>(
              padding: (_) => EdgeInsets.zero,
              data: data,
              variables: {
                'time': Variable(
                  accessor: (entry) => entry.$1,
                  scale: TimeScale(
                    formatter: (p0, visibleRange) {
                      print(visibleRange);

                      return '${p0.day}/${p0.month}';
                    },
                    marginMin: 0,
                  ),
                ),
                'prices': Variable(
                  accessor: (entry) => entry.$2,
                  scale: LinearScale(tickCount: 6),
                ),
              },
              marks: [
                LineMark(
                  color: ColorEncode(value: Colors.lightBlue),
                  selected: {
                    // This is needed to show Crosshair on pre-selected point
                    'hover': {data.length - 1},
                  },
                ),
                PointMark(
                  selected: {
                    'hover': {data.length - 1},
                  },
                  selectionStream: _selectionStream,
                  color: ColorEncode(value: Colors.blue, updaters: {
                    'hover': {true: (_) => Colors.red}
                  }),
                ),
              ],
              coord: RectCoord(
                horizontalRangeUpdater: (init, pre, event) {
                  if (event is GestureEvent) {
                    final gesture = event.gesture;

                    if (gesture.type == GestureType.scaleUpdate) {
                      final detail = gesture.details as ScaleUpdateDetails;

                      // This logic only runs for single-finger pans.
                      if (detail.pointerCount == 1) {
                        final deltaRatio =
                            gesture.preScaleDetail!.focalPointDelta.dx;

                        final delta = deltaRatio / gesture.chartSize.width;

                        final newValue = [
                          pre.first + delta,
                          pre.last + delta,
                        ];

                        // final initRange = init.last - init.first;
                        // final preRange = pre.last - pre.first;
                        // final newRange = newValue.last - newValue.first;

                        if (init.first <= pre.first + delta) {
                          return pre;
                        }

                        if (init.last >= pre.last + delta) {
                          return pre;
                        }

                        return newValue;
                      } else {
                        double getScaleDim(ScaleUpdateDetails p0) =>
                            p0.horizontalScale;
                        final preScale = getScaleDim(
                          gesture.preScaleDetail!,
                        );
                        // horizontal scale value from the previous frame
                        final scale = getScaleDim(detail);
                        // horizontal scale value from the current frame
                        final deltaRatio = (scale - preScale) / preScale / 2;

                        final initRange = init.last - init.first;
                        final preRange = pre.last - pre.first;

                        final delta = deltaRatio * preRange;

                        final isZoomingOut = delta < 0;
                        final isZoomingIn = delta > 0;

                        final newValue = [
                          pre.first - delta,
                          pre.last + delta,
                        ];

                        final newRange = newValue.last - newValue.first;

                        // Zooming in.
                        // TODO(komakur): Find a way to consider data interval
                        // PS: Maybe conversion from normalized 0-1 to DateTime needed
                        if (newRange >= initRange &&
                            (newRange - initRange) >= 0.6 &&
                            isZoomingIn) {
                          return pre;
                        }

                        // Zooming out.
                        // Limited to initial range.
                        if (isZoomingOut) {
                          var values = newValue.toList();

                          // Means our new left edge moves before initial
                          if (newValue.first > init.first) {
                            values = [init.first, newValue.last];
                          }
                          // Means our new right edge moves before initial
                          if (newValue.last < init.last) {
                            values = [values.first, init.last];
                          }
                          // Zooming out more than init not allowed
                          if (newRange <= initRange &&
                              (initRange - newRange) >= 0) {
                            return init;
                          }

                          return values;
                        }

                        return newValue;
                      }
                    } else if (gesture.type == GestureType.doubleTap) {
                      return init;
                    }
                  }
                  return pre;
                },
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.black, Colors.black87],
                ),
              ),
              selections: {
                'hover': PointSelection(
                  on: {
                    GestureType.tap,
                    GestureType.longPressMoveUpdate,
                    GestureType.secondaryLongPressMoveUpdate,
                  },
                  clear: {},
                  variable: 'time',
                  dim: Dim.x,
                ),
              },
              crosshair: CrosshairGuide(
                followPointer: [false, false],
                selections: {'hover'},
                styles: [
                  PaintStyle(strokeColor: Colors.amber),
                  PaintStyle(strokeColor: Colors.transparent),
                ],
              ),
              axes: [
                Defaults.horizontalAxis,
                AxisGuide(
                  line: PaintStyle(
                      strokeColor: Defaults.strokeColor, strokeWidth: 1),
                  // Use grid lines as the primary vertical reference.
                  grid: PaintStyle(
                      strokeColor: const Color(0xffe0e0e0), dash: [2]),
                  // 3. Configure and reposition labels.
                  label: LabelStyle(
                    // Move labels 8px to the right.
                    offset: const Offset(40, 0),
                    // Align text so it starts at the tick mark.
                    align: Alignment.topLeft,
                    textStyle: const TextStyle(
                      color: Color(0xff616161),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
