import 'dart:io';
import 'dart:typed_data';
import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../cache/json_storage.dart';
import '../../../../services/opencv_service.dart';
import '../../../../utils/image_bounding_box/data/box_details.dart';
import '../../../../utils/image_bounding_box/data/box_with_label_and_name.dart';
import '../../../../utils/image_bounding_box/data/image_circle.dart';
import '../../../../utils/image_bounding_box/widgets/image_bounding_box_controller.dart';
import '../../../../utils/image_bounding_box/widgets/image_bounding_box_widget.dart';
import '../../../../utils/utils.dart';
import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../data/answer_sheet_recompute_params.dart';
import '../../data/answer_sheet_template_model.dart';
import '../../data/answer_sheet_identifiable_box.dart';
import '../../widgets/answer_sheet_template_box_creation_dialog_widget.dart';
import '../../widgets/circle_params_editor.dart';
import 'package:corigge/widgets/default_button_widget.dart';

class TemplateSelectionPage extends StatefulWidget {
  const TemplateSelectionPage({
    super.key,
  });

  @override
  State<TemplateSelectionPage> createState() => _TemplateSelectionPageState();
}

class _TemplateSelectionPageState extends State<TemplateSelectionPage> {
  String? pdfLocation;
  String? image;
  int currentPage = 0;
  AnswerSheetRecomputeParams recomputeParams = AnswerSheetRecomputeParams();
  bool loading = false;
  bool loadedTemplates = false;
  PageController pageController = PageController();
  bool shouldDrawNewBox = false;
  ImageBoundingBoxController controller = ImageBoundingBoxController();
  List<AnswerSheetTemplateModel> templates = [];
  AnswerSheetTemplateModel? selectedTemplate;
  BoxDetails? selectedBox;
  String? selectedBoxName;
  bool changedSomething = false;
  bool reloadingCircles = false;
  String? processingText;
  int reloadCounter = 0;
  ImageCircle? hoveredCircle;
  bool hasUnsavedChanges = false;
  AnswerSheetTemplateModel? templateSelectedBefore;

  String? errorFound;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load the selected template from shared preferences
    final savedTemplate = await SharedPreferencesHelper.getSelectedTemplate();
    if (savedTemplate != null) {
      setState(() {
        templateSelectedBefore = savedTemplate;
      });
    }
  }

  Future<void> _saveSelectedTemplate() async {
    await SharedPreferencesHelper.saveSelectedTemplate(selectedTemplate);
  }

  void setChangedSomething({bool shouldRecompute = true}) async {
    setState(() {
      changedSomething = true;
      hasUnsavedChanges = true;
    });
  }

  void reloadCircles() async {
    setState(() {
      reloadingCircles = true;
    });

    var locationOfFile = "${selectedTemplate!.id}.png";

    var fileData = await SharedPreferencesHelper.getImage(locationOfFile);

    if (fileData == null) {
      setState(() {
        reloadingCircles = false;
      });
      return;
    }

    var result = (await OpenCVService.findCircles(
      FileData(
        name: locationOfFile,
        size: fileData.length,
        bytes: fileData,
      ),
      selectedTemplate!.boxes
          .map((e) => BoxWithLabelAndName(
              box: Rect.fromLTWH(
                  (e.box.rect.left + selectedTemplate!.calibrationPoint!.dx) /
                      selectedTemplate!.imageSize!.width,
                  (e.box.rect.top + selectedTemplate!.calibrationPoint!.dy) /
                      selectedTemplate!.imageSize!.height,
                  (e.box.rect.width) / selectedTemplate!.imageSize!.width,
                  (e.box.rect.height) / selectedTemplate!.imageSize!.height),
              label: e.box.label,
              name: e.name))
          .toList(),
      params: selectedTemplate!.circleParams,
    ));

    if (result.isLeft()) {
      setState(() {
        reloadingCircles = false;
      });
      return;
    }

    var circlesPerBox = result.fold((l) => {}, (r) => r);

    selectedTemplate!.boxes.forEach((element) {
      element.circles = circlesPerBox[element.name] ?? [];
      element.hasCalculatedCircles = true;
    });

    await JsonStorage.updateUserData(SharedPreferencesHelper.currentUser!,
        (map) {
      map.putIfAbsent("templates", () => {});
    });

    setState(() {
      reloadingCircles = false;
    });
  }

  Future<bool> loadTemplates() async {
    if (loadedTemplates) return true;

    var value = await SharedPreferencesHelper.loadTemplates();

    value.fold((l) {
      errorFound = l;
    }, (r) {
      templates = r;
    });

    loadedTemplates = true;

    return true;
  }

  String? checkErrorsInTemplate(AnswerSheetTemplateModel model) {
    var hasPdf = model.hasImg;

    var hasMatricula = model.boxes.fold(
        false,
        (previousValue, element) =>
            previousValue || element.box.label == BoxDetailsType.matricula);

    var hasCircleExample = model.boxes.fold(
        false,
        (previousValue, element) =>
            previousValue ||
            element.box.label == BoxDetailsType.exemploCirculo);

    var result = "";

    if (!hasPdf) {
      result += "A imagem do template não foi encontrada\n";
    }

    if (!hasMatricula) {
      result += "A caixa de matrícula não foi encontrada\n";
    }

    if (!hasCircleExample) {
      result += "A caixa de exemplo de círculo não foi encontrada\n";
    }

    return result.isEmpty ? null : result;
  }

  Future<void> handleSelectTemplatePdf() async {
    var pathLocation = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      dialogTitle: "Escolha um PDF ou imagem",
      allowMultiple: false,
      allowedExtensions: ['pdf', "png", "jpg", "jpeg"],
    );

    if (pathLocation == null) return;

    var pdf = pathLocation.files.single;

    setState(() {
      loading = true;
      processingText = "";
    });

    Uint8List fileData;

    if (kIsWeb) {
      fileData = pdf.bytes!;
    } else {
      fileData = await File(pdf.path!).readAsBytes();
    }

    var result = (await OpenCVService.convertPdfToImages(
      FileData(
        name: pdf.name,
        size: fileData.length,
        bytes: fileData,
      ),
      pdf.name,
      onProgress: (progress) {
        setState(() {
          processingText = progress;
        });
      },
    ));

    if (result.isLeft()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Erro ao processar o arquivo: ${result.fold((l) => l, (r) => '')}")));
      setState(() {
        loading = false;
      });
      return;
    }

    var pdfToImagesResult = result.fold((l) => null, (r) => r)!;

    var imageBytes = pdfToImagesResult.imageBytes.entries.firstOrNull;

    if (imageBytes == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    selectedTemplate!.calibrationPoint =
        pdfToImagesResult.calibrationPoints[imageBytes.key];

    selectedTemplate!.imageSize = pdfToImagesResult.imageSizes[imageBytes.key];

    // save image to template_images folder
    var locationOfFile = "${selectedTemplate!.id}.png";
    await SharedPreferencesHelper.saveImage(imageBytes.value, locationOfFile);

    selectedTemplate!.hasImg = true;
    image = locationOfFile;

    await SharedPreferencesHelper.saveTemplates(templates);

    ////widget.onTemplatesChanged();

    setState(() {
      reloadCounter++;
      currentPage = 0;
      loading = false;
    });
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
                color: Colors.transparent,
                child: const Text("Cancelar"),
              ),
              DefaultButtonWidget(
                onPressed: () {
                  setState(() {
                    selectedTemplate!.boxes
                        .firstWhere((b) => b.name == box.name)
                        .circles
                        .firstWhere((e) => e.id == circle.id)
                        .filled = !circle.filled;
                  });

                  Navigator.of(context).pop();
                },
                color: Colors.transparent,
                child: const Text("Alterar Preenchimento"),
              ),
              DefaultButtonWidget(
                onPressed: () async {
                  setState(() {
                    selectedTemplate!.boxes
                        .firstWhere((b) => b.name == box.name)
                        .circles
                        .removeWhere((e) => e.id == circle.id);
                  });

                  //widget.onTemplatesChanged();

                  await SharedPreferencesHelper.saveTemplates(templates);

                  Navigator.of(context).pop();
                },
                color: Colors.transparent,
                child: const Text("Deletar"),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(onWantsToGoBack: () {
        context.go('/home');
      }),
      body: FutureBuilder(
          future: loadTemplates(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (errorFound != null) {
              return Center(
                child: Text(errorFound!),
              );
            }

            return Row(
              children: [
                Expanded(
                    child: ClipRect(
                  child: Column(
                    children: [
                      if (image != null) ...[
                        Expanded(
                          child: ImageBoundingBoxWidget(
                            onCircleSelected: (box, circle) {
                              showDialogToEditCircle(context, box, circle);
                            },
                            selectedCircle: hoveredCircle,
                            onHover: (box, circle) {
                              if (box == null && circle == null) {
                                setState(() {
                                  hoveredCircle = null;
                                  if (selectedBox != null) {
                                    selectedBox!.hoveredOver = false;
                                    selectedBox = null;
                                  }
                                  // Don't clear selectedBoxName here as it's used for clicking
                                });
                                return;
                              }

                              setState(() {
                                if (selectedBox != null &&
                                    box!.box != selectedBox) {
                                  selectedBox!.hoveredOver = false;
                                }
                                selectedBox = box?.box;
                                selectedBox!.hoveredOver = true;

                                if (circle != null) {
                                  // Hovering over a circle
                                  hoveredCircle = circle;
                                } else {
                                  // Hovering over a box (but not a circle) - set it as selected for adding circles
                                  hoveredCircle = null;
                                  selectedBoxName = box?.name;
                                }
                              });
                            },
                            onImageTapped: (position) {
                              if (selectedBoxName != null &&
                                  selectedTemplate != null) {
                                // Find the selected box
                                var box = selectedTemplate!.boxes.firstWhere(
                                    (element) =>
                                        element.name == selectedBoxName);

                                // Use a default radius if no circles exist, otherwise use the first circle's radius
                                double radius = box.circles.isNotEmpty
                                    ? box.circles.first.radius
                                    : (selectedTemplate!
                                            .circleParams.circleSize ??
                                        0.01);

                                // Create new circle with relative coordinates
                                var newCircle = ImageCircle(
                                    id: Utils.generateRandomHexString(16),
                                    Offset(
                                        position.dx -
                                            (selectedTemplate!
                                                    .calibrationPoint!.dx /
                                                selectedTemplate!
                                                    .imageSize!.width),
                                        position.dy -
                                            (selectedTemplate!
                                                    .calibrationPoint!.dy /
                                                selectedTemplate!
                                                    .imageSize!.height)),
                                    radius);

                                setState(() {
                                  box.circles.add(newCircle);
                                  setChangedSomething();
                                });

                                // Save changes
                                SharedPreferencesHelper.saveTemplates(
                                    templates);
                                //widget.onTemplatesChanged();
                              }
                            },
                            key: ValueKey(image! + reloadCounter.toString()),
                            calibrationPoint:
                                selectedTemplate?.calibrationPoint ??
                                    Offset.zero,
                            canDraw: selectedTemplate != null,
                            onImageSizeLoaded: (size) async {
                              if (selectedTemplate == null) return;
                              if (selectedTemplate?.imageSize == null) {
                                selectedTemplate!.imageSize = size;

                                // get calibration rect

                                /* var calibrationPoint =
                                      selectedTemplate!.calibrationPoint!;

                                  // make relative

                                  selectedTemplate!.boxes
                                      .add(AnswerSheetIdentifiableBox(
                                          box: BoxDetails(
                                            box: Rect.fromLTWH(0, 0, 20, 20),
                                            label: "calibration",
                                          ),
                                          name: "Calibration Point"));

                                  await MainMenuService.saveTemplates(
                                      templates);

                                  setState(() {});
                                  //widget.onTemplatesChanged(); */
                              }
                            },
                            imagePath: image!,
                            initialBoxes: [
                              ...selectedTemplate?.boxes.map((e) {
                                    return e.copyWith(
                                        box: e.box
                                          ..hoveredOver =
                                              selectedBoxName == e.name
                                          ..circles = e.circles
                                              .map((e) => ImageCircle.fromJson(
                                                  e.toJson())
                                                ..center = Offset(
                                                    e.center.dx *
                                                        selectedTemplate!
                                                            .imageSize!.width,
                                                    e.center.dy *
                                                        selectedTemplate!
                                                            .imageSize!.height)
                                                ..radius = e.radius *
                                                    selectedTemplate!
                                                        .imageSize!.width)
                                              .toList());
                                  }) ??
                                  [],
                            ],
                            onBoxDrawn: (p0) async {
                              // show dialog to get box name

                              var newBox =
                                  await showDialog<AnswerSheetIdentifiableBox>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                              "Insira os dados da caixa"),
                                          content:
                                              AnswerSheetTemplateBoxCreationDialogWidget(
                                            canSelectExampleCircle:
                                                selectedTemplate!.boxes
                                                    .where((element) =>
                                                        element.box.label ==
                                                        BoxDetailsType
                                                            .exemploCirculo)
                                                    .isEmpty,
                                            canSelectMatricula:
                                                selectedTemplate!.boxes
                                                    .where(
                                                        (element) =>
                                                            element.box.label ==
                                                            BoxDetailsType
                                                                .matricula)
                                                    .isEmpty,
                                            onChosen: (boxName, boxType) async {
                                              var newBox =
                                                  AnswerSheetIdentifiableBox(
                                                name: boxName,
                                                box: BoxDetails(
                                                  rect: p0,
                                                  label: boxType,
                                                ),
                                              );

                                              Navigator.of(context).pop(newBox);
                                            },
                                          ),
                                        );
                                      });

                              if (newBox == null) return null;

                              setState(() {
                                selectedTemplate!.boxes.add(newBox);
                              });

                              // path to template image

                              var locationOfFile =
                                  "${selectedTemplate!.id}.png";

                              var fileData =
                                  await SharedPreferencesHelper.getImage(
                                      locationOfFile);

                              if (fileData == null) {
                                return null;
                              }

                              var newBoxRectCopy = Rect.fromLTWH(
                                  (newBox.box.rect.left +
                                          selectedTemplate!
                                              .calibrationPoint!.dx) /
                                      selectedTemplate!.imageSize!.width,
                                  (newBox.box.rect.top +
                                          selectedTemplate!
                                              .calibrationPoint!.dy) /
                                      selectedTemplate!.imageSize!.height,
                                  (newBox.box.rect.width) /
                                      selectedTemplate!.imageSize!.width,
                                  (newBox.box.rect.height) /
                                      selectedTemplate!.imageSize!.height);

                              // make absolute (add offset of calibration in template)

                              var result =
                                  (await OpenCVService.countCirclesInRect(
                                FileData(
                                  name: locationOfFile,
                                  size: fileData.length,
                                  bytes: fileData,
                                ),
                                [
                                  BoxWithLabelAndName(
                                      box: newBoxRectCopy,
                                      label: newBox.box.label,
                                      name: newBox.name)
                                ],
                                params: selectedTemplate!.circleParams,
                              ));

                              if (result.isLeft()) {
                                return null;
                              }

                              var circlesPerBox =
                                  result.fold((l) => {}, (r) => r);

                              newBox.circles = circlesPerBox[newBox.name] ?? [];

                              newBox.hasCalculatedCircles = true;

                              if (newBox.box.label ==
                                      BoxDetailsType.exemploCirculo &&
                                  newBox.circles.isNotEmpty) {
                                selectedTemplate!.circleParams.circleSize =
                                    newBox.circles.first.radius;

                                // remove circles from all boxes beside this one in order to recalculate
                                selectedTemplate!.boxes
                                    .where((element) =>
                                        element.box.label !=
                                        BoxDetailsType.exemploCirculo)
                                    .forEach((element) {
                                  element.hasCalculatedCircles = false;
                                });
                              }
                              // save template

                              setState(() {});

                              await SharedPreferencesHelper.saveTemplates(
                                  templates);

                              //widget.onTemplatesChanged();

                              return newBox;
                            },
                          ),
                        ),
                      ] else if (selectedTemplate != null) ...[
                        Expanded(
                          child: Center(
                            child: DefaultButtonWidget(
                              onPressed: () async {
                                await handleSelectTemplatePdf();
                              },
                              child: Text(pdfLocation != null
                                  ? "PDF: ${pdfLocation!}"
                                  : "Select PDF file to serve as template"),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                )),
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
                if (selectedTemplate == null) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Select a template to edit",
                              style: TextStyle(
                                  fontSize: getProportionateFontSize(25)),
                            ),
                            IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("Add new template"),
                                          content: TextField(
                                            decoration: const InputDecoration(
                                              hintText: "Template name",
                                            ),
                                            onSubmitted: (value) async {
                                              templates.add(
                                                  AnswerSheetTemplateModel(
                                                      id: Utils
                                                          .generateRandomHexString(
                                                              32),
                                                      name: value,
                                                      boxes: []));

                                              await SharedPreferencesHelper
                                                  .saveTemplates(templates);

                                              //widget.onTemplatesChanged();

                                              setState(() {});
                                              // ignore: use_build_context_synchronously
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        );
                                      });
                                },
                                icon: const Icon(Icons.add))
                          ],
                        ),
                        Expanded(
                          child: Builder(builder: (context) {
                            return ListView.builder(
                              itemCount: templates.length,
                              itemBuilder: (context, index) {
                                var templateErrors =
                                    checkErrorsInTemplate(templates[index]);

                                Widget returnWidget = ListTile(
                                  tileColor: templateErrors != null
                                      ? kWarning
                                      : (selectedTemplate?.id ==
                                              templates[index].id
                                          ? kSecondary
                                          : null),
                                  title: Row(
                                    children: [
                                      Text(
                                        templates[index].name,
                                        style: TextStyle(
                                            color: selectedTemplate?.id ==
                                                        templates[index].id ||
                                                    templateErrors != null
                                                ? kOnSurface
                                                : null),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                          color: selectedTemplate?.id ==
                                                      templates[index].id ||
                                                  templateErrors != null
                                              ? kOnSurface
                                              : null,
                                          onPressed: () async {
                                            var locationOfFile =
                                                "${templates[index].id}.png";

                                            if (await SharedPreferencesHelper
                                                .imageExists(locationOfFile)) {
                                              image = locationOfFile;
                                            }

                                            setState(() {
                                              selectedTemplate =
                                                  templates[index];
                                            });

                                            recomputeParams =
                                                AnswerSheetRecomputeParams(
                                              reapplyTemplate: true,
                                              shouldRecomputeAllCards: true,
                                            );

                                            //widget.onRecomputeParamsChanged(
                                            //    recomputeParams);
                                          },
                                          icon: const Icon(Icons.edit)),
                                      SizedBox(
                                        width: getProportionateScreenWidth(10),
                                      ),
                                      IconButton(
                                          color: selectedTemplate?.id ==
                                                      templates[index].id ||
                                                  templateErrors != null
                                              ? kOnSurface
                                              : null,
                                          onPressed: () async {
                                            if (selectedTemplate ==
                                                templates[index]) {
                                              selectedTemplate = null;
                                            }

                                            templates.removeAt(index);

                                            await SharedPreferencesHelper
                                                .saveTemplates(templates);
                                            //widget.onTemplatesChanged();

                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.delete))
                                    ],
                                  ),
                                  onTap: templateErrors != null
                                      ? null
                                      : () async {
                                          //widget.onTemplateChosen(
                                          //    templates[index]);
                                          selectedTemplate = templates[index];
                                          if (selectedTemplate!.hasImg) {
                                            image =
                                                "${selectedTemplate!.id}.png";
                                          }
                                          await _saveSelectedTemplate();
                                          // ignore: use_build_context_synchronously
                                          context.go('/home');
                                        },
                                );

                                if (templateErrors != null) {
                                  returnWidget = Tooltip(
                                    message: templateErrors,
                                    child: returnWidget,
                                  );
                                }

                                return returnWidget;
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(child: Builder(builder: (context) {
                    if (reloadingCircles) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Recalculando círculos...",
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: getProportionateScreenHeight(10)),
                          const CircularProgressIndicator(),
                        ],
                      );
                    }

                    return loading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Loading PDF...\n${processingText ?? ""}",
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(10)),
                              const CircularProgressIndicator(),
                            ],
                          )
                        : SizedBox(
                            height: double.infinity,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              image = null;
                                              changedSomething = false;
                                              selectedTemplate = null;
                                            });
                                            await _saveSelectedTemplate();
                                          },
                                          icon: const Icon(
                                              Icons.arrow_back_ios_new))),
                                  SizedBox(
                                    height: getProportionateScreenHeight(10),
                                  ),

                                  Row(
                                    children: [
                                      const Spacer(),
                                      Text(
                                        "Template: ${selectedTemplate!.name}",
                                        style: TextStyle(
                                            fontSize:
                                                getProportionateFontSize(28)),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (changedSomething &&
                                                hasUnsavedChanges) ...[
                                              IconButton(
                                                onPressed: () {
                                                  reloadCircles();
                                                },
                                                icon: const Tooltip(
                                                    message: "Reload circles",
                                                    child: Icon(Icons.refresh)),
                                              ),
                                              SizedBox(
                                                width:
                                                    getProportionateScreenWidth(
                                                        10),
                                              ),
                                            ],
                                            IconButton(
                                                onPressed: () async {
                                                  await handleSelectTemplatePdf();
                                                },
                                                icon: const Tooltip(
                                                    message:
                                                        "Select a new PDF to serve as template",
                                                    child: Icon(Icons.image))),
                                            SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      10),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),

                                  SizedBox(
                                    height: getProportionateScreenHeight(10),
                                  ),
                                  if (changedSomething &&
                                      hasUnsavedChanges) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                            "Recomputar círculos com base em alterações?"),
                                        Checkbox(
                                          value: recomputeParams
                                              .shouldRecomputeAllCards,
                                          onChanged: (value) {
                                            setState(() {
                                              recomputeParams =
                                                  recomputeParams.copyWith(
                                                      shouldRecomputeAllCards:
                                                          value);
                                            });
                                            //widget.onRecomputeParamsChanged(
                                            //    recomputeParams);
                                          },
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: getProportionateScreenHeight(10),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                            "Reaplicar valores do template?"),
                                        Checkbox(
                                          value:
                                              recomputeParams.reapplyTemplate,
                                          onChanged: (value) {
                                            setState(() {
                                              recomputeParams =
                                                  recomputeParams.copyWith(
                                                      reapplyTemplate: value);
                                            });
                                            //widget.onRecomputeParamsChanged(
                                            //    recomputeParams);
                                          },
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: getProportionateScreenHeight(10),
                                    ),
                                  ],
                                  CircleParamsEditor(
                                      circleParams:
                                          selectedTemplate!.circleParams,
                                      onParamsChanged: (params) async {
                                        setState(() {
                                          selectedTemplate!.circleParams =
                                              params;

                                          setChangedSomething();
                                        });

                                        //widget.onTemplatesChanged();

                                        await SharedPreferencesHelper
                                            .saveTemplates(templates);
                                      }),
                                  Container(
                                    height: 2,
                                    width: double.infinity,
                                    color: Colors.black,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(10),
                                  ),
                                  //listview of boxes that can be selected/removed

                                  Builder(builder: (context) {
                                    // sort boxes by putting matricula first, exemplo de circulo second and the rest as it is

                                    selectedTemplate!.boxes.sort((a, b) {
                                      if (a.box.label ==
                                          BoxDetailsType.matricula) {
                                        return -1;
                                      }

                                      if (b.box.label ==
                                          BoxDetailsType.matricula) {
                                        return 1;
                                      }

                                      if (a.box.label ==
                                          BoxDetailsType.exemploCirculo) {
                                        return -1;
                                      }

                                      if (b.box.label ==
                                          BoxDetailsType.exemploCirculo) {
                                        return 1;
                                      }

                                      return 0;
                                    });

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: selectedTemplate!.boxes.length,
                                      itemBuilder: (context, index) {
                                        return MouseRegion(
                                          onEnter: (d) {
                                            setState(() {
                                              selectedBox = selectedTemplate!
                                                  .boxes[index].box;
                                              selectedBox!.hoveredOver = true;
                                              selectedBoxName =
                                                  selectedTemplate!
                                                      .boxes[index].name;
                                            });
                                          },
                                          onExit: (d) {
                                            setState(() {
                                              selectedBox!.hoveredOver = false;
                                              selectedBox = null;
                                              selectedBoxName = null;
                                            });
                                          },
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                Builder(builder: (context) {
                                                  var caixa = selectedTemplate!
                                                      .boxes[index];
                                                  String nome =
                                                      Utils.getBoxNameByLabel(
                                                          caixa);

                                                  var finalText =
                                                      "$nome - ${selectedTemplate!.boxes[index].hasCalculatedCircles == false ? 'carregando ' : "${selectedTemplate!.boxes[index].circles.length} "}círculos";

                                                  if (caixa.box.label ==
                                                      BoxDetailsType.outro) {
                                                    var labels = Utils
                                                            .getEncodedLabels(
                                                                caixa)
                                                        .map((e) =>
                                                            "\n${Uri.decodeComponent(e)}");

                                                    finalText +=
                                                        labels.join("");
                                                  }

                                                  return Text(finalText);
                                                }),
                                              ],
                                            ),
                                            onTap: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (_) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          "Deseja remover ${Utils.getBoxNameByLabel(selectedTemplate!.boxes[index])}?"),
                                                      actions: [
                                                        DefaultButtonWidget(
                                                            onPressed: () {
                                                              Navigator.of(_)
                                                                  .pop();
                                                            },
                                                            color: Colors
                                                                .transparent,
                                                            child: const Text(
                                                                "Cancel")),
                                                        DefaultButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              selectedTemplate!
                                                                  .boxes
                                                                  .removeAt(
                                                                      index);

                                                              await SharedPreferencesHelper
                                                                  .saveTemplates(
                                                                      templates);

                                                              //widget
                                                              //    .onTemplatesChanged();

                                                              // ignore: use_build_context_synchronously
                                                              Navigator.of(_)
                                                                  .pop();
                                                              setState(() {});
                                                            },
                                                            color: Colors
                                                                .transparent,
                                                            child: const Text(
                                                                "Remover"))
                                                      ],
                                                    );
                                                  });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                  }))
                ]
              ],
            );
          }),
    );
  }
}
