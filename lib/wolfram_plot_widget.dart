import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:plotting_app/plot_data_form.dart';
import 'package:plotting_app/secrets.dart';

class LoadedPlotWidget extends StatelessWidget {
  final PlotData data;

  final WolframPlotLoader _plotLoader;

  LoadedPlotWidget({Key key, this.data})
      : _plotLoader = WolframPlotLoader(data),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _plotLoader.getPlotUrl(),
        builder: (BuildContext context, AsyncSnapshot<NetworkImage> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Image(image: snapshot.data),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Container(
              height: 280,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}

class WolframPlotLoader {
  final PlotData plotData;

  WolframPlotLoader(this.plotData);

  Uri _buildUri() => Uri.http("api.wolframalpha.com", "/v2/query", {
        "appid": WOLFRAM_API_KEY,
        "input":
            "plot ${plotData.expString} from ${plotData.min} to ${plotData.max}",
        "format": "image",
        "output": "json"
      });

  Future<NetworkImage> getPlotUrl() => http
      .get(_buildUri())
      .then((response) => NetworkImage(parseResponse(response), scale: 1.0));

  String parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final pods = jsonData["queryresult"]["pods"];
      for (var pod in pods) {
        if (pod["title"] == "Plot") {
          return pod["subpods"][0]["img"]["src"];
        }
      }
    } else {
      throw UnsupportedError(
          "Unsuccessful response with code ${response.statusCode}");
    }
  }
}
