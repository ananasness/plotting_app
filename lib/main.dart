import 'package:flutter/material.dart';
import 'package:plotting_app/plot_data_form.dart';
import 'package:plotting_app/plot_widget.dart';
import 'package:plotting_app/wolfram_plot_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plotting App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget plotWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Plotting App"),
      ),
      body: Column(
        children: [
          PlotDataForm(
            onFormSubmitted: (PlotData plotData, bool isWolfram) {
              setState(() {
                plotWidget = isWolfram
                    ? LoadedPlotWidget(data: plotData)
                    : PlotWidget(
                        data: plotData,
                      );
              });
            },
            onError: () {
              setState(() {
                plotWidget = null;
              });
            },
          ),
          if (plotWidget != null) plotWidget
        ],
      ),
    );
  }
}
