import 'package:flutter/material.dart';
import '../../../config/size_config.dart';
import '../data/python_circle_identification_params.dart';
import '../../../widgets/selectable_button_widget.dart';

class CircleParamsEditor extends StatefulWidget {
  const CircleParamsEditor({
    super.key,
    required this.circleParams,
    required this.onParamsChanged,
  });

  final PythonCircleIdentificationParams circleParams;
  final Function(PythonCircleIdentificationParams) onParamsChanged;

  @override
  State<CircleParamsEditor> createState() => _CircleParamsEditorState();
}

class _CircleParamsEditorState extends State<CircleParamsEditor> {
  late PythonCircleIdentificationParams circleParams;

  @override
  void initState() {
    super.initState();

    circleParams = widget.circleParams;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text("Estilo de Identificação"),
            SizedBox(
              width: getProportionateScreenWidth(30),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message:
                          "Usa o método de visão computacional e IA para identificar círculos\nMais preciso, porém mais lento",
                      child: SelectableButtonWidget(
                        disabled: false,
                        selected: !circleParams.useFallbackMethod,
                        onPressed: (v) {
                          setState(() {
                            circleParams.useFallbackMethod = false;
                            widget.onParamsChanged(circleParams);
                          });
                        },
                        child: Text("VC"),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: getProportionateScreenWidth(10),
                  ),
                  Expanded(
                    child: Tooltip(
                      message:
                          "Usa um método de identificação de círculos mais simples.\nMenos preciso, porém mais rápido",
                      child: SelectableButtonWidget(
                          selected: circleParams.useFallbackMethod,
                          onPressed: (v) {
                            setState(() {
                              circleParams.useFallbackMethod = true;
                              widget.onParamsChanged(circleParams);
                            });
                          },
                          child: Text("Simples")),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: getProportionateScreenHeight(10),
        ),
        for (var entry in circleParams.toJson().entries.toList()
          ..removeWhere((e) =>
              e.key == "circle_size" ||
              e.value is! double ||
              e.key != "darkness_threshold")) ...[
          Builder(builder: (context) {
            var paramsDesc =
                PythonCircleIdentificationParams.getDescriptionForParams();
            var paramsNames =
                PythonCircleIdentificationParams.getNameForParams();
            var paramsMinMax =
                PythonCircleIdentificationParams.getMinMaxForParams();

            var paramDesc = paramsDesc[entry.key]!;
            var paramName = paramsNames[entry.key]!;
            var paramMinMax = paramsMinMax[entry.key]!;

            return Column(
              children: [
                Row(
                  children: [
                    Text(paramName),
                    SizedBox(
                      width: getProportionateScreenWidth(10),
                    ),
                    Tooltip(message: paramDesc, child: Icon(Icons.info)),
                  ],
                ),
                Slider(
                    label: entry.value.toString(),
                    value: entry.value,
                    onChanged: (value) {
                      setState(() {
                        circleParams =
                            PythonCircleIdentificationParams.fromJson(
                                circleParams.toJson()..[entry.key] = value);
                      });
                      widget.onParamsChanged(circleParams);
                    },
                    min: paramMinMax.min,
                    max: paramMinMax.max),
              ],
            );
          }),
          SizedBox(
            height: getProportionateScreenHeight(10),
          ),
        ],
      ],
    );
  }
}
