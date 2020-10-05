import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plotting_app/plot_data_form.dart';

class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}

class PlotWidget extends StatelessWidget {
  static const POINTS_BY_PLOT = 300;

  final double Function(double) func;
  final double minVal;
  final double maxVal;

  PlotWidget({Key key, PlotData data})
      : this.func = data.expression,
        this.minVal = data.min,
        this.maxVal = data.max,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 280,
      padding: EdgeInsets.all(20),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.infinite,
        painter: CurvePainter(
          points: preparePlotData(),
          minX: minVal,
          maxX: maxVal,
        ),
      ),
    );
  }

  List<Point> preparePlotData() {
    // divide x interval into [POINTS_BY_PLOT] points and calc func for them
    final step = (maxVal - minVal) / POINTS_BY_PLOT;
    final xs = List<double>.generate(POINTS_BY_PLOT, (i) => minVal + i * step);
    return xs
        .map((x) => Point(x, func(x)))
        .where((p) => p.y != double.infinity && !p.y.isNaN)
        .toList();
  }
}

class CurvePainter extends CustomPainter {
  final List<Point> points;
  final double minX;
  final double maxX;
  double minY, maxY;

  CurvePainter(
      {@required this.points, @required this.minX, @required this.maxX}) {
    minY = points.map((p) => p.y).reduce(min);
    maxY = points.map((p) => p.y).reduce(max);
    if (minY == maxY) {
      minY = minX;
      maxY = maxX;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawAxis(canvas, size);
    _drawCurve(canvas, size);
  }

  void _drawCurve(Canvas canvas, Size size) {
    Paint curvePaint = Paint();
    curvePaint.color = Colors.blue;
    curvePaint.strokeWidth = 2.0;

    if (points.length < 2) {
      return;
    }
    Point prevPoint = points[0];
    for (var point in points.sublist(1, points.length - 1)) {
      // Not so smart way to find a break point of the curve and avoid connection there
      if ((prevPoint.y - point.y).abs() == maxY - minY) {
        prevPoint = point;
        continue;
      }
      canvas.drawLine(
          _scalePoint(prevPoint, size), _scalePoint(point, size), curvePaint);
      prevPoint = point;
    }
  }

  void _drawAxis(Canvas canvas, Size size) {
    Paint axisPaint = Paint();
    axisPaint.color = Colors.black;
    axisPaint.strokeWidth = 1.0;

    final double xAxisX = max(minX, 0);
    final double yAxisY = max(minY, 0);

    // draw axis lines
    canvas.drawLine(_scaleCoordinates(xAxisX, minY, size),
        _scaleCoordinates(xAxisX, maxY, size), axisPaint);
    canvas.drawLine(_scaleCoordinates(minX, yAxisY, size),
        _scaleCoordinates(maxX, yAxisY, size), axisPaint);

    // draw axis labels
    _drawLabel("x", _scaleCoordinates(maxX, yAxisY, size), canvas);
    _drawLabel("y", _scaleCoordinates(xAxisX, maxY, size), canvas);

    Paint gridLinePaint = Paint();
    gridLinePaint.color = Colors.grey;
    gridLinePaint.strokeWidth = 1.0;

    _drawXGridLines(Point(xAxisX, yAxisY), canvas, size, gridLinePaint);
    _drawYGridLines(Point(xAxisX, yAxisY), canvas, size, gridLinePaint);
  }

  void _drawLabel(String text, Offset pos, Canvas canvas,
      {TextStyle textStyle, TextAlign textAlign}) {
    TextPainter label = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle ?? TextStyle(color: Colors.black),
      ),
      textAlign: textAlign ?? TextAlign.center,
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    label.layout(minWidth: 20);
    label.paint(canvas, pos);
  }

  double log10(num x) => log(x) / ln10;

  // get number of digits in the int part of number like 1234567.89 -> 7
  double _getCountOfDigits(double number) {
    return (number == 0) ? 1 : log10(number.abs() + 0.5).ceilToDouble();
  }

  double _getGridStep(double interval) {
    // calc grid step so that there will be appropriate number of grid lines
    double _nextStep(double step) {
      // get next step less than previous like
      // 100 -> 50 -> 20 -> 10 -> ...
      final divider = pow(10, (_getCountOfDigits(step / 2) - 1));
      return ((step ~/ 2) ~/ divider) * divider;
    }

    // search for the step until there are 4 or more grid lines
    double step = pow(10, _getCountOfDigits(interval.ceilToDouble()) - 1);
    // TODO: add supporting steps < 1
    while ((interval / step).ceil() < 4 && step > 1) {
      step = _nextStep(step);
    }
    return step;
  }

  void _drawXGridLines(Point origin, Canvas canvas, Size size, Paint paint) {
    final gridStepX = _getGridStep(maxX - minX);
    double currentLineX = (minX / gridStepX).ceilToDouble() * gridStepX;
    while (currentLineX < maxX - gridStepX / 4) {
      final startPoint =
          _scaleCoordinates(currentLineX.toDouble(), origin.y, size);
      canvas.drawLine(startPoint, startPoint + Offset(0, -3), paint);

      _drawLabel(_numToString(currentLineX), startPoint, canvas,
          textStyle: TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.left);

      currentLineX += gridStepX;
    }
  }

  void _drawYGridLines(Point origin, Canvas canvas, Size size, Paint paint) {
    final gridStepY = _getGridStep(maxY - minY);
    double currentLineY = (minY / gridStepY).ceilToDouble() * gridStepY;
    while (currentLineY < maxY) {
      if (currentLineY == origin.x) {
        // avoid double drawing at the origin
        currentLineY += gridStepY;
        continue;
      }
      final startPoint =
          _scaleCoordinates(origin.x, currentLineY.toDouble(), size);
      canvas.drawLine(startPoint, startPoint + Offset(3, 0), paint);

      _drawLabel(
          _numToString(currentLineY), startPoint + Offset(-34, -8), canvas,
          textStyle: TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center);

      currentLineY += gridStepY;
    }
  }

  String _numToString(double num) {
    if (num.abs() >= 1e4) {
      final digitsCount = _getCountOfDigits(num) - 1;
      // for some reasons .toStringAsExponential works bad in some cases (like 3.00000000004e+63)
      // that's why here is manual formatting
      return "${num < 0 ? "-" : ""}${(num / pow(10, digitsCount)).ceil()}e+${digitsCount.toInt()}";
    } else {
      return num.ceil().toString();
    }
    // TODO: add supporting super small values like 0.0000006 -> 6e-7
  }

  Offset _scalePoint(Point point, Size size) =>
      _scaleCoordinates(point.x, point.y, size);

  // scale points coordinates from real (x,y) values to canvas coordinates
  Offset _scaleCoordinates(double x, double y, size) {
    // 15 - reserve vertical space for grid numbers
    double scaledX = (x - minX) / (maxX - minX) * (size.width - 15) + 15;
    double scaledY = (maxY - y) / (maxY - minY) * size.height;
    return Offset(scaledX, scaledY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
