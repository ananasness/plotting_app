import 'package:flutter/material.dart';
import 'package:plotting_app/parser.dart';

class PlotData {
  final Expression expression;
  final String expString;
  final double min;
  final double max;

  PlotData({this.expression, this.expString, this.min, this.max});
}

class PlotDataForm extends StatefulWidget {
  final void Function(PlotData) onFormSubmitted;

  const PlotDataForm({Key key, this.onFormSubmitted}) : super(key: key);

  @override
  _PlotDataFormState createState() => _PlotDataFormState();
}

class _PlotDataFormState extends State<PlotDataForm> {
  final Parser _parser = Parser();
  TextEditingController _controller;
  TextEditingController _minController;
  TextEditingController _maxController;
  String errorMessage;

  void initState() {
    super.initState();
    _controller = TextEditingController();
    _minController = TextEditingController();
    _maxController = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Enter an expression with x as a variable',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("f(x) = "),
            SizedBox(
                width: 300,
                child: TextField(
                  controller: _controller,
                ))
          ],
        ),
        SizedBox(height: 10),
        Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Enter limits for the variable',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("x ∈  {"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: 60,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _minController,
                ),
              ),
            ),
            Text(","),
            SizedBox(
                width: 60,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _maxController,
                )),
            Text("}"),
          ],
        ),
        RaisedButton(child: Text("Plot"), onPressed: onPlotButtonClick),
        if (errorMessage != null)
          Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 14)),
      ],
    );
  }

  void onPlotButtonClick() {
    setState(() {
      this.errorMessage = tryToSubmitForm();
    });
    FocusScope.of(context).unfocus();
  }

  String tryToSubmitForm() {
    print(_minController);
    final minVal = double.tryParse(_minController.text);
    if (minVal == null) {
      return "Incorrect Min value";
    }
    final maxVal = double.tryParse(_maxController.text);
    if (maxVal == null) {
      return "Incorrect Max value";
    }

    if (minVal >= maxVal) {
      return "Min should be more than max";
    }

    Expression exp;
    try {
      exp = _parser.parse(_controller.text);
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      return "Incorrect expression";
    }
    if (exp == null || minVal == null || maxVal == null) {
      return "Something went wrong. Please try again";
    }

    widget.onFormSubmitted(PlotData(
        expression: exp,
        expString: _controller.text,
        min: minVal,
        max: maxVal));
    return null;
  }
}
