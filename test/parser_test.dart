import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotting_app/parser.dart';

void main() {
  bool isEqual(double actual, dynamic expected) {
    if (actual.isNaN) {
      return expected == "NAN";
    } else if (actual == double.infinity) {
      return expected == "INF";
    } else {
      return actual == expected;
    }
  }

  test('Test parse method', () async {
    final testData =
        json.decode(await File('test/parser_test_data.json').readAsString());
    final values = testData["values"];
    final cases = testData["cases"];

    final parser = Parser();

    for (var expression in cases.keys) {
      if (cases[expression].isEmpty) {
        expect(() => parser.parse(expression), throwsFormatException,
            reason: "case: $expression");
      } else {
        final lambda = parser.parse(expression);

        for (var i = 0; i < values.length; i++) {
          final reasonStr = "case: $expression\n"
              "${expression.replaceAll("x", values[i].toString())} = ${lambda(values[i])}\n"
              "expected ${cases[expression][i]}";

          expect(isEqual(lambda(values[i]), cases[expression][i]), true,
              reason: reasonStr);
        }
      }
    }
  });
}
