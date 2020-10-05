import 'package:flutter/material.dart';
import 'package:plotting_app/plot_data_form.dart';

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
      appBar: AppBar(
        title: Text("Plotting App"),
      ),
      body: Column(
        children: [
          PlotDataForm(
            onFormSubmitted: (PlotData plotData) {
              setState(() {
                plotWidget = Text("The plot is here!");
              });
            },
          ),
          if (plotWidget != null) plotWidget
        ],
      ),
    );
  }
}
