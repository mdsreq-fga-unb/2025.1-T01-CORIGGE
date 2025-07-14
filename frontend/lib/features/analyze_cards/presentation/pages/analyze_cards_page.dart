import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../services/opencv_service.dart';
import '../../../../utils/image_bounding_box/data/box_details.dart';
import '../../../../utils/image_bounding_box/data/box_with_label_and_name.dart';
import '../../../../utils/image_bounding_box/data/image_circle.dart';
import '../../../../utils/image_bounding_box/widgets/image_bounding_box_controller.dart';
import '../../../../utils/image_bounding_box/widgets/image_bounding_box_widget.dart';
import '../../../../utils/utils.dart';
import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../../templates/data/answer_sheet_card_model.dart';
import '../../../templates/data/answer_sheet_recompute_params.dart';
import '../../../templates/data/answer_sheet_template_model.dart';
import '../../../templates/widgets/circle_params_editor.dart';
import '../../../templates/data/answer_sheet_identifiable_box.dart';
import 'package:corigge/widgets/default_button_widget.dart';

class AnalyzeCardsPage extends StatefulWidget {
  const AnalyzeCardsPage({super.key});

  @override
  State<AnalyzeCardsPage> createState() => _AnalyzeCardsPageState();
}

class _AnalyzeCardsPageState extends State<AnalyzeCardsPage> {
  String? pdfLocation;
  AnswerSheetCardModel? imageCard;
  int currentPage = 0;
  bool loading = false;
  bool loadedCards = false;
  PageController pageController = PageController();
  List<AnswerSheetCardModel> cards = [];
  bool shouldDrawNewBox = false;
  ImageBoundingBoxController controller = ImageBoundingBoxController();
  AnswerSheetCardModel? selectedCard;
  ImageCircle? selectedCircle;
  String? selectedBox;
  bool shouldDrawBalls = true;
  AnswerSheetTemplateModel? selectedTemplate;

  Map<String, bool> isBoxOpen = {};

  int processingNumber = 0;
  int totalProcessing = 0;
  String processingMessage = "";
  bool processing = false;
  Timer? processingTimer;
  DateTime? processingStartTime;
  String processingDuration = "";
  String processingSpeed = "";

  String? errorFound;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    processingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Load the selected template
    final template = await SharedPreferencesHelper.getSelectedTemplate();
    if (template != null) {
      setState(() {
        selectedTemplate = template;
      });
    }

    // Load saved cards
    final cardsResult = await SharedPreferencesHelper.loadCards();
    cardsResult.fold((error) {
      setState(() {
        errorFound = error;
      });
    }, (loadedCards) {
      setState(() {
        cards = loadedCards
          ..sort((a, b) =>
              a.documentOriginalName.compareTo(b.documentOriginalName));
      });
    });

    loadedCards = true;
  }

  void showDialogToEditCircle(BuildContext context,
      AnswerSheetIdentifiableBox box, ImageCircle circle) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("O que você deseja fazer?"),
            actions: [
              DefaultButtonWidget(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: kSuccess,
                child: const Text("Cancelar"),
              ),
              DefaultButtonWidget(
                onPressed: () {
                  setState(() {
                    selectedCard!.circlesPerBox[box.name]!
                        .firstWhere((e) => e.id == circle.id)
                        .filled = !circle.filled;
                  });
                  _saveCards();
                  Navigator.of(context).pop();
                },
                color: kSuccess,
                child: const Text("Alterar Preenchimento"),
              ),
              DefaultButtonWidget(
                onPressed: () {
                  setState(() {
                    selectedCard!.circlesPerBox[box.name]!
                        .removeWhere((e) => e.id == circle.id);
                  });
                  _saveCards();
                  Navigator.of(context).pop();
                },
                color: kError,
                child: const Text("Deletar"),
              )
            ],
          );
        });
  }

  Future<void> _saveCards() async {
    await SharedPreferencesHelper.saveCards(cards);
  }

  Future<void> computeCirclesForBoxes(
      AnswerSheetCardModel model, AnswerSheetRecomputeParams params) async {
    if (selectedTemplate == null) return;

    bool needsProcessingUpdate = true;
    if (processing) {
      needsProcessingUpdate = false;
    }

    if (needsProcessingUpdate) {
      setState(() {
        processing = true;
        totalProcessing = model.circlesPerBox.length;
        processingNumber = 1;
        processingMessage = "Iniciando processamento...";
        processingStartTime = DateTime.now();
        processingDuration = "";
        processingSpeed = "";
      });

      // Start timer
      processingTimer?.cancel();
      processingTimer =
          Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (mounted && processingStartTime != null) {
          final elapsed = DateTime.now().difference(processingStartTime!);
          final seconds = elapsed.inSeconds;
          final milliseconds = elapsed.inMilliseconds % 1000;
          final elapsedMinutes = elapsed.inMilliseconds / 60000.0;

          setState(() {
            processingDuration =
                "${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}s";

            // Calculate processing speed (gabaritos/min)
            if (elapsedMinutes > 0) {
              final speed = processingNumber / elapsedMinutes;
              processingSpeed = "${speed.toStringAsFixed(1)} gabaritos/min";
            } else {
              processingSpeed = "";
            }
          });
        }
      });
    }

    model.circlesPerBox = Map<String, List<ImageCircle>>.from({});

    var boxesByLabel = selectedTemplate!.boxes.map((box) {
      var boxRelative = Rect.fromLTWH(
          (box.box.rect.left + selectedTemplate!.calibrationPoint!.dx) /
              selectedTemplate!.imageSize!.width,
          (box.box.rect.top + selectedTemplate!.calibrationPoint!.dy) /
              selectedTemplate!.imageSize!.height,
          (box.box.rect.width) / selectedTemplate!.imageSize!.width,
          (box.box.rect.height) / selectedTemplate!.imageSize!.height);

      return BoxWithLabelAndName(
          box: boxRelative,
          label: box.box.label,
          name: box.name,
          templateCircles:
              box.circles.map((e) => ImageCircle(e.center, e.radius)).toList());
    }).toList();

    var fileData = await SharedPreferencesHelper.getImage(model.path);

    setState(() {
      processingMessage = "Processando círculos...";
    });

    var result = await OpenCVService.findCircles(
      FileData(
        name: model.path,
        size: fileData!.length,
        bytes: fileData,
      ),
      boxesByLabel,
      params: model.circleParams
        ..circleSize = selectedTemplate!.circleParams.circleSize,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            processingMessage = progress;
          });
        }
      },
    );

    if (result.isLeft()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Erro ao processar imagem ${model.documentOriginalName}, ${result.fold((l) => l, (r) => null)}")));
      return;
    }

    var circlesPerBox = result.fold((l) => <String, List<ImageCircle>>{},
        (r) => Map<String, List<ImageCircle>>.from(r));

    setState(() {
      processingMessage = "Organizando círculos encontrados...";
    });

    for (var box in selectedTemplate!.boxes) {
      var circles = circlesPerBox[box.name] ?? [];

      circles.sort((a, b) {
        if ((a.center.dy - b.center.dy).abs() < 10) {
          return a.center.dx.compareTo(b.center.dx);
        }
        return a.center.dy.compareTo(b.center.dy);
      });

      circlesPerBox[box.name] = circles;

      if (needsProcessingUpdate && mounted) {
        setState(() {
          processingNumber++;
          processingMessage = "Processando caixa ${box.name}...";
        });
      }
    }

    model.circlesPerBox = circlesPerBox;

    if (needsProcessingUpdate) {
      setState(() {
        processing = false;
        processingNumber = 0;
        totalProcessing = 0;
        processingMessage = "";
        processingDuration = "";
        processingSpeed = "";
      });
      processingTimer?.cancel();
    }

    await _saveCards();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTemplate == null) {
      return Scaffold(
        appBar: AppBarCustom.appBarWithLogo(onWantsToGoBack: () {
          context.go('/home');
        }),
        body: const Center(
          child: Text("Por favor, selecione um template primeiro"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(onWantsToGoBack: () {
        context.go('/home');
      }),
      body: Row(
        children: [
          Expanded(
            child: ClipRect(
              child: Column(
                children: [
                  if (imageCard != null) ...[
                    Expanded(
                      child: ImageBoundingBoxWidget(
                        onCircleSelected: (box, circle) {
                          if (selectedCard != null) {
                            showDialogToEditCircle(context, box, circle);
                          }
                        },
                        onHover: (box, circle) {
                          if (box == null && circle == null) {
                            setState(() {
                              selectedCircle = null;
                            });
                            return;
                          }
                          if (selectedCard != null) {
                            setState(() {
                              if (box != null) {
                                selectedBox = box.name;
                              }

                              if (circle != null) {
                                selectedCircle = imageCard!
                                    .circlesPerBox[box!.name]
                                    ?.where(
                                        (element) => element.id == circle.id)
                                    .firstOrNull;
                              }
                            });
                          }
                        },
                        onImageTapped: (position) {
                          if (selectedBox != null && selectedCard != null) {
                            var box = selectedTemplate!.boxes.firstWhere(
                                (element) => element.name == selectedBox);
                            var exampleCircle = box.circles.first;

                            var newCircle = ImageCircle(
                                id: Utils.generateRandomHexString(16),
                                Offset(
                                    position.dx -
                                        (selectedTemplate!
                                                .calibrationPoint!.dx /
                                            selectedCard!.imageSize!.width),
                                    position.dy -
                                        (selectedTemplate!
                                                .calibrationPoint!.dy /
                                            selectedCard!.imageSize!.height)),
                                exampleCircle.radius);

                            setState(() {
                              selectedCard!.circlesPerBox[selectedBox]
                                  ?.add(newCircle);
                            });

                            _saveCards();
                          }
                        },
                        key: ValueKey(imageCard!.path),
                        selectedCircle: selectedCircle,
                        calibrationPoint: imageCard!.calibrationPoint,
                        imageAngle: imageCard!.imageAngle,
                        imageOffset: imageCard!.imageOffset,
                        onImageSizeLoaded: (size) async {
                          imageCard!.imageSize = size;
                        },
                        canDraw: false,
                        imagePath: imageCard!.path,
                        initialBoxes: [
                          ...selectedTemplate!.boxes
                              .where((e) => imageCard!.imageSize != null)
                              .map((identifiableBox) {
                            var newBox =
                                BoxDetails.fromJson(identifiableBox.toJson())
                                  ..rect = Rect.fromLTWH(
                                      identifiableBox.box.rect.left /
                                          selectedTemplate!.imageSize!.width *
                                          imageCard!.imageSize!.width,
                                      identifiableBox.box.rect.top /
                                          selectedTemplate!.imageSize!.height *
                                          imageCard!.imageSize!.height,
                                      identifiableBox.box.rect.width /
                                          selectedTemplate!.imageSize!.width *
                                          imageCard!.imageSize!.width,
                                      identifiableBox.box.rect.height /
                                          selectedTemplate!.imageSize!.height *
                                          imageCard!.imageSize!.height);

                            if (shouldDrawBalls) {
                              newBox.circles = imageCard!
                                      .circlesPerBox[identifiableBox.name]
                                      ?.map((e) =>
                                          ImageCircle.fromJson(e.toJson())
                                            ..center = Offset(
                                                e.center.dx *
                                                    imageCard!.imageSize!.width,
                                                e.center.dy *
                                                    imageCard!
                                                        .imageSize!.height)
                                            ..radius = e.radius *
                                                imageCard!.imageSize!.width)
                                      .toList() ??
                                  [];
                            }

                            if (selectedBox == identifiableBox.name) {
                              newBox.hoveredOver = true;
                            }

                            return identifiableBox.copyWith(box: newBox);
                          })
                        ],
                        onBoxDrawn: (p0) async {
                          return null;
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          Container(
              width: getProportionateScreenWidth(10),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              )),
          if (processing) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: getProportionateScreenHeight(10)),
                    Text("Processando...",
                        style: TextStyle(
                            fontSize: getProportionateFontSize(20),
                            color: kOnSurface)),
                    if (processingDuration.isNotEmpty) ...[
                      SizedBox(height: getProportionateScreenHeight(5)),
                      Text(
                        processingDuration,
                        style: TextStyle(
                            fontSize: getProportionateFontSize(16),
                            color: kOnSurface,
                            fontFamily: 'monospace'),
                      ),
                      if (processingSpeed.isNotEmpty) ...[
                        SizedBox(height: getProportionateScreenHeight(3)),
                        Text(
                          processingSpeed,
                          style: TextStyle(
                              fontSize: getProportionateFontSize(14),
                              color: kOnSurface,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                    SizedBox(height: getProportionateScreenHeight(10)),
                    Text(
                      processingMessage,
                      style: TextStyle(
                          fontSize: getProportionateFontSize(20),
                          color: kOnSurface),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            )
          ] else if (selectedCard == null) ...[
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Escolha um cartão resposta para editar",
                        style:
                            TextStyle(fontSize: getProportionateFontSize(25)),
                      ),
                      IconButton(
                          onPressed: () {
                            FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowMultiple: true,
                                allowedExtensions: [
                                  'pdf',
                                  "png",
                                  "jpg",
                                  "jpeg"
                                ]).then((value) async {
                              if (value != null) {
                                setState(() {
                                  processing = true;
                                  processingNumber = 1;
                                  totalProcessing = value.files.length;
                                  processingStartTime = DateTime.now();
                                  processingDuration = "";
                                  processingSpeed = "";
                                });

                                // Start timer for file processing
                                processingTimer?.cancel();
                                processingTimer = Timer.periodic(
                                    const Duration(milliseconds: 50), (timer) {
                                  if (mounted && processingStartTime != null) {
                                    final elapsed = DateTime.now()
                                        .difference(processingStartTime!);
                                    final seconds = elapsed.inSeconds;
                                    final milliseconds =
                                        elapsed.inMilliseconds % 1000;
                                    final elapsedMinutes =
                                        elapsed.inMilliseconds / 60000.0;

                                    setState(() {
                                      processingDuration =
                                          "${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}s";

                                      // Calculate processing speed (gabaritos/min)
                                      if (elapsedMinutes > 0) {
                                        final speed =
                                            processingNumber / elapsedMinutes;
                                        processingSpeed =
                                            "${speed.toStringAsFixed(1)} gabaritos/min";
                                      } else {
                                        processingSpeed = "";
                                      }
                                    });
                                  }
                                });

                                for (var file in value.files) {
                                  Uint8List fileData;

                                  if (kIsWeb) {
                                    fileData = file.bytes!;
                                  } else {
                                    fileData =
                                        await File(file.path!).readAsBytes();
                                  }

                                  var result =
                                      await OpenCVService.convertPdfToImages(
                                    FileData(
                                      name: file.name,
                                      size: fileData.length,
                                      bytes: fileData,
                                    ),
                                    file.name,
                                    onProgress: (progress) {
                                      setState(() {
                                        processingMessage = progress;
                                      });
                                    },
                                  );

                                  if (result.isLeft()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Erro ao processar arquivo ${file.name}, ${result.fold((l) => l, (r) => null)}")));
                                    continue;
                                  }

                                  var pdfToImagesResult =
                                      result.fold((l) => null, (r) => r)!;

                                  for (var image
                                      in pdfToImagesResult.imageBytes.keys) {
                                    await SharedPreferencesHelper.saveImage(
                                        pdfToImagesResult.imageBytes[image]!,
                                        "$image.png");

                                    var model = AnswerSheetCardModel(
                                        documentOriginalName: file.name,
                                        path: "$image.png",
                                        calibrationPoint: pdfToImagesResult
                                            .calibrationPoints[image]!)
                                      ..imageSize =
                                          pdfToImagesResult.imageSizes[image]!
                                      ..circleParams = selectedTemplate!
                                          .circleParams
                                          .copyWith();

                                    await computeCirclesForBoxes(
                                        model, AnswerSheetRecomputeParams());

                                    cards.add(model);
                                  }

                                  processingNumber++;
                                }

                                await _saveCards();

                                setState(() {
                                  processing = false;
                                  totalProcessing = 0;
                                  processingNumber = 0;
                                  processingDuration = "";
                                  processingSpeed = "";
                                });
                                processingTimer?.cancel();
                              }
                            });
                          },
                          icon: const Icon(Icons.add))
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return MouseRegion(
                          onEnter: (event) async {
                            setState(() {
                              imageCard = cards[index];
                            });
                          },
                          child: ListTile(
                            tileColor:
                                imageCard == cards[index] ? kSecondary : null,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cards[index].documentOriginalName,
                                    style: TextStyle(
                                      color: imageCard == cards[index]
                                          ? kOnSurface
                                          : kOnSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: getProportionateScreenWidth(10)),
                                Builder(builder: (context) {
                                  var value = cards[index]
                                      .circlesPerBox
                                      .entries
                                      .fold(true, (previousValue, element) {
                                    return previousValue &&
                                        selectedTemplate?.boxes
                                                .where((e) =>
                                                    element.key == e.name)
                                                .firstOrNull
                                                ?.circles
                                                .length ==
                                            element.value.length;
                                  });

                                  return Icon(
                                    value ? Icons.check : Icons.error,
                                    color: value ? kSuccess : kError,
                                  );
                                }),
                                SizedBox(
                                    width: getProportionateScreenWidth(10)),
                                IconButton(
                                    color: imageCard == cards[index]
                                        ? kOnSurface
                                        : kOnSurface,
                                    onPressed: () async {
                                      setState(() {
                                        cards.removeAt(index);
                                        imageCard = null;
                                      });
                                      await _saveCards();
                                    },
                                    icon: const Icon(Icons.delete))
                              ],
                            ),
                            onTap: () async {
                              setState(() {
                                selectedCard = cards[index];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else if (selectedCard!.imageSize == null) ...[
            const Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text("Carregando Imagem"),
                    CircularProgressIndicator()
                  ],
                ),
              ),
            )
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              setState(() {
                                imageCard = null;
                                selectedCard = null;
                              });
                            },
                            icon: const Icon(Icons.arrow_back_ios_new)),
                        Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: selectedCard != cards.first
                                  ? () {
                                      setState(() {
                                        var index =
                                            cards.indexOf(selectedCard!);
                                        selectedCard = cards[index - 1];
                                        imageCard = selectedCard;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios_new),
                            ),
                            SizedBox(width: getProportionateScreenWidth(10)),
                            Text(
                                "${cards.indexOf(selectedCard!) + 1}/${cards.length}",
                                style: TextStyle(
                                    fontSize: getProportionateFontSize(20))),
                            SizedBox(width: getProportionateScreenWidth(10)),
                            IconButton(
                              onPressed: selectedCard != cards.last
                                  ? () {
                                      setState(() {
                                        var index =
                                            cards.indexOf(selectedCard!);
                                        selectedCard = cards[index + 1];
                                        imageCard = selectedCard;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(10)),
                    Row(
                      children: [
                        Text(
                          "Cartão: ${selectedCard!.documentOriginalName}",
                          style:
                              TextStyle(fontSize: getProportionateFontSize(25)),
                        ),
                        Builder(builder: (context) {
                          var value = selectedCard!.circlesPerBox.entries
                              .fold(true, (previousValue, element) {
                            return previousValue &&
                                selectedTemplate?.boxes
                                        .where((e) => element.key == e.name)
                                        .firstOrNull
                                        ?.circles
                                        .length ==
                                    element.value.length;
                          });

                          return Icon(
                            value ? Icons.check : Icons.error,
                            color: value ? kSuccess : kError,
                          );
                        }),
                        const Spacer(),
                        Tooltip(
                          message:
                              "${shouldDrawBalls ? 'Ocultar' : 'Mostrar'} Círculos",
                          child: IconButton(
                              onPressed: () {
                                setState(() {
                                  shouldDrawBalls = !shouldDrawBalls;
                                });
                              },
                              icon: Icon(shouldDrawBalls
                                  ? Icons.visibility
                                  : Icons.visibility_off)),
                        ),
                        SizedBox(width: getProportionateScreenWidth(10)),
                        Tooltip(
                          message: "Recomputar Circulos",
                          child: IconButton(
                              onPressed: () async {
                                await computeCirclesForBoxes(selectedCard!,
                                    AnswerSheetRecomputeParams());
                                setState(() {});
                              },
                              icon: const Icon(Icons.refresh)),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(10)),
                    CircleParamsEditor(
                        circleParams: selectedCard!.circleParams,
                        onParamsChanged: (params) {
                          setState(() {
                            selectedCard!.circleParams = params;
                          });
                          _saveCards();
                        }),
                    SizedBox(height: getProportionateScreenHeight(10)),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: selectedTemplate!.boxes.length,
                      itemBuilder: (context, index) {
                        var box = selectedTemplate!.boxes[index];
                        var circles =
                            selectedCard!.circlesPerBox[box.name] ?? [];

                        return MouseRegion(
                          onEnter: (event) {
                            setState(() {
                              selectedBox = box.name;
                            });
                          },
                          onExit: (event) {
                            setState(() {
                              selectedBox = null;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                  onTap: () {
                                    setState(() {
                                      isBoxOpen[box.name] = !isBoxOpen
                                          .putIfAbsent(box.name, () => false);
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Text(
                                        "${Utils.getBoxNameByLabel(box)} | Circulos Encontrados: ${circles.length}/${box.circles.length} ",
                                        style: TextStyle(
                                            fontSize:
                                                getProportionateFontSize(20)),
                                      ),
                                      Icon(
                                        circles.length == box.circles.length
                                            ? Icons.check
                                            : Icons.error,
                                        color:
                                            circles.length == box.circles.length
                                                ? kSuccess
                                                : kError,
                                      )
                                    ],
                                  ),
                                  subtitle: Text(
                                    "Círculos: ${circles.length}",
                                    style: TextStyle(
                                        fontSize: getProportionateFontSize(20)),
                                  ),
                                  trailing: Icon(isBoxOpen.putIfAbsent(
                                          box.name, () => false)
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down)),
                              if (isBoxOpen.putIfAbsent(
                                  box.name, () => false)) ...[
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: getProportionateScreenWidth(20)),
                                  child: GridView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 8),
                                    children: circles.map((circle) {
                                      return MouseRegion(
                                        onEnter: (event) {
                                          setState(() {
                                            selectedBox = box.name;
                                            selectedCircle = circle;
                                          });
                                        },
                                        child: DefaultButtonWidget(
                                          onPressed: () {
                                            showDialogToEditCircle(
                                                context, box, circle);
                                          },
                                          color: Colors.transparent,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        "x: ${circle.center.dx * selectedCard!.imageSize!.width} y: ${circle.center.dy * selectedCard!.imageSize!.height}",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                getProportionateFontSize(
                                                                    15))),
                                                    Text(
                                                        "Raio: ${circle.radius * selectedCard!.imageSize!.width}",
                                                        style: TextStyle(
                                                            fontSize:
                                                                getProportionateFontSize(
                                                                    13))),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  width:
                                                      getProportionateScreenWidth(
                                                          5)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}
