import 'package:flutter/material.dart';
import 'package:corigge/config/size_config.dart';
import 'package:corigge/utils/utils.dart';
import 'package:corigge/utils/image_bounding_box/data/box_details.dart';
import 'package:corigge/widgets/default_button_widget.dart';

class AnswerSheetTemplateBoxCreationDialogWidget extends StatefulWidget {
  const AnswerSheetTemplateBoxCreationDialogWidget({
    super.key,
    required this.onChosen,
    required this.canSelectMatricula,
    required this.canSelectExampleCircle,
  });

  final Function(String boxName, String boxType) onChosen;
  final bool canSelectMatricula;
  final bool canSelectExampleCircle;

  @override
  State<AnswerSheetTemplateBoxCreationDialogWidget> createState() =>
      _AnswerSheetTemplateBoxCreationDialogWidgetState();
}

class _AnswerSheetTemplateBoxCreationDialogWidgetState
    extends State<AnswerSheetTemplateBoxCreationDialogWidget> {
  String boxName = "type_b_1";
  String boxType = BoxDetailsType.colunaDeQuestoes;
  TextEditingController controller = TextEditingController(text: "1");
  TextEditingController labelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.canSelectExampleCircle) {
      boxType = BoxDetailsType.exemploCirculo;
      boxName = "exemplo_circulo";
    }
  }

  List<String> getEncodedLabels() {
    if (boxType != BoxDetailsType.outro) return [];

    var boxLabels = boxName.split("_");

    List<String> finalBoxLabels = [];

    if (boxLabels.length >= 2 && boxLabels[2].isNotEmpty) {
      finalBoxLabels = boxLabels.sublist(2);
    }

    return finalBoxLabels;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var labels =
          getEncodedLabels().map((e) => Uri.decodeComponent(e)).toList();
      return SizedBox(
        height: getProportionateScreenHeight(600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Tipo de Caixa"),
              SizedBox(
                height: getProportionateScreenHeight(10),
              ),
              DropdownButton<String>(
                value: boxType,
                onChanged: (String? newValue) {
                  setState(() {
                    boxType = newValue!;
                    if (boxType == BoxDetailsType.matricula) {
                      boxName = "matricula";
                    } else if (boxType == BoxDetailsType.colunaDeQuestoes) {
                      boxName = "column_ac_1";
                      controller.text = "1";
                    } else if (boxType == BoxDetailsType.typeB) {
                      boxName = "type_b_1";
                      controller.text = "1";
                    } else if (boxType == BoxDetailsType.outro) {
                      boxName = "outro__";
                      controller.text = "";
                    } else if (boxType == BoxDetailsType.exemploCirculo) {
                      boxName = "exemplo_circulo";
                    }
                  });
                },
                items: <String>[
                  if (widget.canSelectExampleCircle)
                    BoxDetailsType.exemploCirculo
                  else ...[
                    if (widget.canSelectMatricula) BoxDetailsType.matricula,
                    BoxDetailsType.colunaDeQuestoes,
                    BoxDetailsType.typeB,
                    BoxDetailsType.outro,
                  ]
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              if (boxType == BoxDetailsType.outro) ...[
                Text("Nome da Caixa"),
                SizedBox(
                  height: getProportionateScreenHeight(10),
                ),
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    setState(() {
                      var finalBoxLabels = getEncodedLabels();

                      boxName =
                          "outro_${Uri.encodeComponent(value)}_${finalBoxLabels.join("_")}";
                    });
                  },
                ),
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
                Text("Labels"),
                SizedBox(
                  height: getProportionateScreenHeight(10),
                ),
                ...labels.indexed.map(
                  (e) {
                    var index = e.$1;
                    var label = e.$2;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Label ${index + 1} -"),
                        SizedBox(
                          width: getProportionateScreenWidth(10),
                        ),
                        Text('"$label"'),
                        SizedBox(
                          width: getProportionateScreenWidth(10),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              labels.removeAt(index);
                              labels = labels
                                  .map((e) => Uri.encodeComponent(e))
                                  .toList();
                              boxName =
                                  "outro_${boxName.split("_")[1]}_${labels.join("_")}";
                            });
                          },
                        )
                      ],
                    );
                  },
                ),
                Divider(),
                TextField(
                  inputFormatters: [],
                  onChanged: (v) {
                    setState(() {});
                  },
                  controller: labelController,
                ),
                if (labelController.text.isNotEmpty) ...[
                  SizedBox(
                    height: getProportionateScreenHeight(10),
                  ),
                  DefaultButtonWidget(
                    onPressed: () {
                      setState(() {
                        var finalBoxLabels = getEncodedLabels();
                        finalBoxLabels
                            .add(Uri.encodeComponent(labelController.text));
                        boxName =
                            "outro_${boxName.split("_")[1]}_${finalBoxLabels.join("_")}";
                        labelController.clear();
                      });
                    },
                    child: Text("Adicionar Label"),
                  ),
                ],
              ],
              if ((boxType != BoxDetailsType.matricula &&
                      boxType != BoxDetailsType.exemploCirculo) &&
                  boxType != BoxDetailsType.outro) ...[
                Text(boxType == BoxDetailsType.typeB
                    ? "Numero da Questão"
                    : "Número da Questão Topo"),
                SizedBox(
                  height: getProportionateScreenHeight(10),
                ),
                TextField(
                  controller: controller,
                  inputFormatters: [
                    RangeTextInputFormatter(
                        lowerBound: 1, upperBound: 999, decimalPlaces: 0)
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (boxType == BoxDetailsType.typeB) {
                        boxName = "type_b_$value";
                      } else {
                        boxName = "column_ac_$value";
                      }
                    });
                  },
                ),
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
              ],
              if ((controller.text.isNotEmpty &&
                      ((boxType == BoxDetailsType.outro &&
                              getEncodedLabels().isNotEmpty) ||
                          boxType != BoxDetailsType.outro)) ||
                  boxType == BoxDetailsType.matricula) ...[
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
                DefaultButtonWidget(
                  onPressed: () {
                    widget.onChosen(boxName, boxType);
                  },
                  child: Text("Criar Caixa"),
                )
              ],
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    labelController.dispose();
    super.dispose();
  }
}
