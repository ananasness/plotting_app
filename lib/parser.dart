import 'package:string_validator/string_validator.dart';

enum TokenTypeName {
  MINUS,
  PLUS,
  UN_MINUS,
  MULTI,
  DIV,
  VAL,
  VAR,
  OPEN_BRACE,
  CLOSE_BRACE,
}

class Token {
  final TokenTypeName typeName;
  final bool isOperator;

  Token(this.typeName, [this.isOperator = false]);

  @override
  String toString() {
    return typeName.toString().split(".")[1];
  }
}

abstract class Operator extends Token {
  final int priority;

  Operator(typeName, this.priority) : super(typeName, true);
}

class BinOperator extends Operator {
  final double Function(double a, double b) eval;

  BinOperator(typeName, priority, this.eval) : super(typeName, priority);
}

class UnOperator extends Operator {
  final double Function(double a) eval;

  UnOperator(typeName, priority, this.eval) : super(typeName, priority);
}

class ValueToken extends Token {
  final double value;

  ValueToken(this.value) : super(TokenTypeName.VAL);

  @override
  String toString() {
    return "${super.toString()}(${value.toString()})";
  }
}

const VARIABLE_NAME = "x";

typedef Expression = double Function(double x);

final plusOperator = BinOperator(TokenTypeName.PLUS, 1, (a, b) => a + b);
final minusOperator = BinOperator(TokenTypeName.MINUS, 1, (a, b) => a - b);
final unMinusOperator = UnOperator(TokenTypeName.UN_MINUS, 3, (a) => -a);
final multiOperator = BinOperator(TokenTypeName.MULTI, 2, (a, b) => a * b);
final divOperator = BinOperator(TokenTypeName.DIV, 2, (a, b) => a / b);

class Parser {
  static final operators = {
    TokenTypeName.PLUS: plusOperator,
    TokenTypeName.MINUS: minusOperator,
    TokenTypeName.UN_MINUS: unMinusOperator,
    TokenTypeName.MULTI: multiOperator,
    TokenTypeName.DIV: divOperator,
    TokenTypeName.OPEN_BRACE: Token(TokenTypeName.OPEN_BRACE, false),
    TokenTypeName.CLOSE_BRACE: Token(TokenTypeName.CLOSE_BRACE, false),
  };

  static final keys2type = {
    "+": TokenTypeName.PLUS,
    "-": TokenTypeName.MINUS,
    "*": TokenTypeName.MULTI,
    "/": TokenTypeName.DIV,
    "(": TokenTypeName.OPEN_BRACE,
    ")": TokenTypeName.CLOSE_BRACE,
  };

  List<Token> _extractTokens(String input) {
    List<Token> tokens = [];
    List<String> numberBuffer = [];
    List<String> wordBuffer = [];

    Token prevToken;

    for (var symbol in input.split("") + [" "]) {
      bool addedToBuffer = false;
      // parse numbers
      if (_isProbablyNumeric(symbol)) {
        numberBuffer.add(symbol);
        addedToBuffer = true;
      } else if (numberBuffer.isNotEmpty) {
        final token = ValueToken(double.parse(numberBuffer.join()));
        numberBuffer.clear();
        tokens.add(token);
        prevToken = tokens.last;
      }

      // parse letters and words
      if (isAlpha(symbol)) {
        wordBuffer.add(symbol);
        addedToBuffer = true;
      } else if (wordBuffer.isNotEmpty) {
        final word = wordBuffer.join();
        Token token;
        if (keys2type.containsKey(word)) {
          token = _getTokenByKey(word);
        } else if (word == VARIABLE_NAME) {
          token = Token(TokenTypeName.VAR);
        } else {
          throw FormatException("Unexpected word '$word' cannot be parsed");
        }
        wordBuffer.clear();
        tokens.add(token);
        prevToken = tokens.last;
      }

      if (addedToBuffer) {
        continue;
      }

      // recognize unary minus
      if (symbol == "-" &&
          (prevToken == null ||
              prevToken.typeName == TokenTypeName.OPEN_BRACE ||
              prevToken.isOperator)) {
        tokens.add(operators[TokenTypeName.UN_MINUS]);
        // parse operators and braces
      } else if (keys2type.containsKey(symbol)) {
        tokens.add(_getTokenByKey(symbol));
        // parse variable
      } else if (symbol == " ") {
        continue;
      } else {
        throw FormatException("Unexpected symbol '$symbol' cannot be parsed");
      }

      prevToken = tokens.last;
    }

    return tokens;
  }

  bool _isProbablyNumeric(String s) => isNumeric(s) || s == "." || s == ",";

  Token _getTokenByKey(String key) => operators[keys2type[key]];

  List<Token> _shuntingYard(List<Token> tokens) {
    List<Token> stack = [];
    List<Token> output = [];

    for (var token in tokens) {
      if (token.typeName == TokenTypeName.VAL ||
          token.typeName == TokenTypeName.VAR) {
        output.add(token);
      } else if (token is Operator) {
        while (stack.isNotEmpty) {
          final last = stack.last;
          if (last is Operator &&
              last.priority >= token.priority &&
              !(token is UnOperator)) {
            output.add(stack.removeLast());
          } else {
            break;
          }
        }
        stack.add(token);
      } else if (token.typeName == TokenTypeName.OPEN_BRACE) {
        stack.add(token);
      } else if (token.typeName == TokenTypeName.CLOSE_BRACE) {
        while (stack.isNotEmpty &&
            stack.last.typeName != TokenTypeName.OPEN_BRACE) {
          output.add(stack.removeLast());
        }
        if (stack.isEmpty) {
          throw FormatException(
              "Not valid braces configuration. Impossible to parse");
        }
        stack.removeLast();
      }
    }

    while (stack.isNotEmpty) {
      if (stack.last.typeName == TokenTypeName.OPEN_BRACE) {
        throw FormatException(
            "Not valid braces configuration. Impossible to parse");
      }

      output.add(stack.removeLast());
    }

    return output;
  }

  double Function(double) _getLambda(List<Token> tokensRPN) {
    List<Expression> stack = [];

    try {
      for (var token in tokensRPN) {
        if (token is ValueToken) {
          stack.add((x) => token.value);
        } else if (token is UnOperator) {
          final last = stack.removeLast();
          stack.add((x) => token.eval(last(x)));
        } else if (token is BinOperator) {
          final right = stack.removeLast();
          final left = stack.removeLast();
          stack.add((x) => token.eval(left(x), right(x)));
        } else if (token.typeName == TokenTypeName.VAR) {
          stack.add((x) => x);
        }
      }
    } on RangeError {
      throw FormatException("Not possible to evaluate incorrect expression");
    }

    if (stack.length != 1) {
      throw FormatException("Not possible to evaluate incorrect expression");
    }

    return stack.first;
  }

  Expression parse(String input) =>
      _getLambda(_shuntingYard(_extractTokens(input)));
}
