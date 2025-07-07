import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../../../utils/utils.dart';
import '../../../cache/shared_preferences_helper.dart';
import '../../../features/templates/data/answer_sheet_identifiable_box.dart';
import '../data/box_details.dart';
import '../data/image_circle.dart';
import 'image_bounding_box_controller.dart';
import 'image_bounding_box_painter.dart';
import 'image_circles_painter.dart';

class ImageBoundingBoxWidget extends StatefulWidget {
  final String imagePath;
  final List<AnswerSheetIdentifiableBox> initialBoxes;
  final Future<AnswerSheetIdentifiableBox?> Function(Rect) onBoxDrawn;
  final Function(Size) onImageSizeLoaded;
  final Offset? calibrationPoint;
  final bool canDraw;
  final Offset? imageOffset;
  final double? imageAngle;
  final ImageCircle? selectedCircle;
  final Function(AnswerSheetIdentifiableBox?, ImageCircle?) onHover;
  final Function(AnswerSheetIdentifiableBox, ImageCircle) onCircleSelected;
  final Function(Offset)? onImageTapped;

  const ImageBoundingBoxWidget(
      {required this.imagePath,
      required this.onHover,
      required this.initialBoxes,
      required this.onImageSizeLoaded,
      required this.onCircleSelected,
      required this.onBoxDrawn,
      this.selectedCircle,
      this.imageAngle,
      this.imageOffset,
      this.calibrationPoint,
      this.onImageTapped,
      this.canDraw = true,
      Key? key})
      : super(key: key);

  @override
  State<ImageBoundingBoxWidget> createState() => _ImageBoundingBoxWidgetState();
}

class _ImageBoundingBoxWidgetState extends State<ImageBoundingBoxWidget> {
  Offset? startDrag;
  Offset? currentDrag;
  ui.Image? image;
  GlobalKey imageKey = GlobalKey();
  Size? imageSize;
  ImageProvider? imageProvider;
  double lastScale = 1.0;
  Offset? lastFocalPoint;
  String? loadedImagePath;
  Pair<AnswerSheetIdentifiableBox, ImageCircle>? hoveredCircle;
  bool _hasDragged = false; // Track if user has dragged
  static const double _dragThreshold =
      5.0; // Minimum distance to consider it a drag

  void onUpdateTransform() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _loadImage(String imagePath) async {
    if (loadedImagePath == widget.imagePath) {
      return true;
    }

    loadedImagePath = widget.imagePath;

    var imageData = await SharedPreferencesHelper.getImage(imagePath);

    if (imageData == null) {
      print("Image data is null");
      return false;
    }

    imageProvider = Image.memory(imageData).image;

    final ImageStream stream =
        imageProvider!.resolve(const ImageConfiguration());
    final completer = Completer<ui.Image>();
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
      if (listener != null) {
        stream.removeListener(listener);
      }
    });
    stream.addListener(listener);
    image = await completer.future;

    widget.onImageSizeLoaded(
        Size(image!.width.toDouble(), image!.height.toDouble()));
    imageSize = Size(image!.width.toDouble(), image!.height.toDouble());
    if (mounted) {
      setState(() {});
    }

    return true;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      // Convert local position to position within transformed image
      final transformedPosition = _transformPoint(details.localPosition);
      startDrag = transformedPosition;
      currentDrag = transformedPosition;
      _hasDragged = false; // Reset drag tracking
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Convert local position to position within transformed image
      currentDrag = _transformPoint(details.localPosition);

      // Check if user has dragged beyond threshold
      if (startDrag != null && currentDrag != null) {
        final distance = (currentDrag! - startDrag!).distance;
        if (distance > _dragThreshold) {
          _hasDragged = true;
        }
      }
    });
  }

// Helper method to transform a point from the local coordinate system
// to the coordinate system of the transformed image
  Offset _transformPoint(Offset point) {
    return point;
  }

  void _onPanEnd(DragEndDetails details) async {
    print("ON PAN END");
    if (startDrag != null && currentDrag != null && _hasDragged) {
      // Only create box if user actually dragged
      var startDragInner = Offset(startDrag!.dx - lastImageDestinationRect.left,
          startDrag!.dy - lastImageDestinationRect.top);

      var currentDragInner = Offset(
          currentDrag!.dx - lastImageDestinationRect.left,
          currentDrag!.dy - lastImageDestinationRect.top);

      var currentDraggingRect =
          Rect.fromPoints(startDragInner, currentDragInner);

      //convert current rect to relative to last image rect
      var calibrationPointConverted = Offset(
          widget.calibrationPoint!.dx /
              imageSize!.width *
              lastImageDestinationRect.width,
          widget.calibrationPoint!.dy /
              imageSize!.height *
              lastImageDestinationRect.height);

      currentDraggingRect = Rect.fromLTWH(
        (currentDraggingRect.left /
                lastImageDestinationRect.width *
                imageSize!.width) -
            calibrationPointConverted.dx,
        (currentDraggingRect.top /
                lastImageDestinationRect.height *
                imageSize!.height) -
            calibrationPointConverted.dy,
        currentDraggingRect.width /
            lastImageDestinationRect.width *
            imageSize!.width,
        currentDraggingRect.height /
            lastImageDestinationRect.height *
            imageSize!.height,
      );

      var newBox = await widget.onBoxDrawn(currentDraggingRect);
      if (newBox != null) {
        widget.initialBoxes.add(newBox);
      }
    }

    if (mounted) {
      setState(() {
        startDrag = null;
        currentDrag = null;
        // Don't reset _hasDragged here as onTapDown might be called after onPanEnd
      });

      // Reset _hasDragged after the current frame to allow onTapDown to read the correct value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasDragged = false;
          });
        }
      });
    }
  }

  Rect lastImageDestinationRect = Rect.zero;

  @override
  Widget build(BuildContext context) {
    _loadImage(widget.imagePath);

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onPanStart: widget.canDraw ? _onPanStart : null,
          onPanUpdate: widget.canDraw ? _onPanUpdate : null,
          onPanEnd: widget.canDraw ? _onPanEnd : null,
          child: LayoutBuilder(builder: (context, constraints) {
            if (image == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            /* if (imageKey.currentContext == null || oldSize != currentSize) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    setState(() {
                      oldSize = currentSize;
                      imageSize = Size(imageKey.currentContext!.size!.width,
                          imageKey.currentContext!.size!.height);
                    });
                  });
                } */
            if (widget.calibrationPoint == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // Include in-progress box if available
            List<AnswerSheetIdentifiableBox> drawingBoxes =
                List.from(widget.initialBoxes); // Copy current boxes

            // convert boxes from relative to last image rect to absolute
            drawingBoxes = drawingBoxes.map((identifiableBox) {
              var e = identifiableBox.box;

              return identifiableBox.copyWith(
                  box: BoxDetails.fromJson(e.toJson())
                    ..rect = Rect.fromLTWH(
                      (e.rect.left + widget.calibrationPoint!.dx) /
                          imageSize!.width,
                      (e.rect.top + widget.calibrationPoint!.dy) /
                          imageSize!.height,
                      e.rect.width / imageSize!.width,
                      e.rect.height / imageSize!.height,
                    )
                    ..circles = e.circles
                        .map((e) => e
                          ..center = Offset(
                              (e.center.dx + widget.calibrationPoint!.dx) /
                                  imageSize!.width,
                              (e.center.dy + widget.calibrationPoint!.dy) /
                                  imageSize!.height)
                          ..radius = e.radius / imageSize!.width)
                        .toList()
                    ..hoveredOver = e.hoveredOver);
            }).toList();

            // transform from relative to absolute

            if (startDrag != null &&
                currentDrag != null &&
                lastImageDestinationRect.contains(startDrag!) &&
                lastImageDestinationRect.contains(currentDrag!)) {
              var startDragInner = Offset(
                  startDrag!.dx - lastImageDestinationRect.left,
                  startDrag!.dy - lastImageDestinationRect.top);

              var currentDragInner = Offset(
                  currentDrag!.dx - lastImageDestinationRect.left,
                  currentDrag!.dy - lastImageDestinationRect.top);

              var currentDraggingRect =
                  Rect.fromPoints(startDragInner, currentDragInner);

              currentDraggingRect = Rect.fromLTWH(
                currentDraggingRect.left / lastImageDestinationRect.width,
                currentDraggingRect.top / lastImageDestinationRect.height,
                currentDraggingRect.width / lastImageDestinationRect.width,
                currentDraggingRect.height / lastImageDestinationRect.height,
              );

              drawingBoxes.add(AnswerSheetIdentifiableBox(
                  box: BoxDetails(
                      rect: currentDraggingRect, label: BoxDetailsType.temp),
                  name: "_temp"));
            }

            var matrix = Matrix4.identity();

            if (widget.imageOffset != null) {
              // convert image offset to relative

              var imageOffset = widget.imageOffset == null
                  ? Offset.zero
                  : Offset(
                      widget.imageOffset!.dx /
                          imageSize!.width *
                          lastImageDestinationRect.width,
                      widget.imageOffset!.dy /
                          imageSize!.height *
                          lastImageDestinationRect.height);

              matrix.translate(imageOffset.dx, imageOffset.dy);
            }

            if (widget.imageAngle != null) {
              matrix.translate(lastImageDestinationRect.width / 2,
                  lastImageDestinationRect.height / 2);
              matrix.rotateZ(widget.imageAngle! * 3.1415926535 / 180.0);
              matrix.translate(-lastImageDestinationRect.width / 2,
                  -lastImageDestinationRect.height / 2);
            }

            var boxesOnlyInner = drawingBoxes.map((e) => e.box).toList();

            return ClipRect(
              key: imageKey,
              child: CustomPaint(
                  foregroundPainter: ImageBoundingBoxPainter(
                      onImageRectChanged: (rect) {
                        lastImageDestinationRect = rect;
                      },
                      onTransformationChange: (matrix) {},
                      image: image,
                      boxes: boxesOnlyInner),
                  child: Transform(
                    transform: matrix,
                    child: GestureDetector(
                      onTapDown: (details) {
                        if (hoveredCircle != null) {
                          widget.onCircleSelected(
                              hoveredCircle!.first, hoveredCircle!.second);
                        } else if (widget.onImageTapped != null &&
                            !_hasDragged) {
                          // Only call onImageTapped if user didn't drag
                          // Convert tap position to relative coordinates
                          var relativeX = details.localPosition.dx /
                              lastImageDestinationRect.width;
                          var relativeY = details.localPosition.dy /
                              lastImageDestinationRect.height;
                          widget.onImageTapped!(Offset(relativeX, relativeY));
                        }
                      },
                      child: MouseRegion(
                        onHover: (d) {
                          // find the circle that is hovered over first (circles have priority)
                          var circles = drawingBoxes
                              .where(
                                  (element) => element.box.circles.isNotEmpty)
                              .expand((element) => element.box.circles
                                  .map((e) => Pair(element, e)))
                              .toList();

                          var hoveredCirclePairDistances =
                              circles.where((pair) {
                            // check if the mouse is over the circle
                            var element = pair.second;

                            var circleCenter = Offset(
                                element.center.dx *
                                    lastImageDestinationRect.width,
                                element.center.dy *
                                    lastImageDestinationRect.height);

                            var distance = sqrt(pow(
                                    circleCenter.dx - d.localPosition.dx, 2) +
                                pow(circleCenter.dy - d.localPosition.dy, 2));

                            return distance <
                                element.radius * lastImageDestinationRect.width;
                          });

                          var hoveredCirclePair =
                              hoveredCirclePairDistances.firstOrNull;

                          if (hoveredCirclePair != null) {
                            // Hovering over a circle
                            widget.onHover(hoveredCirclePair.first,
                                hoveredCirclePair.second);
                            hoveredCircle = hoveredCirclePair;
                          } else {
                            // Not hovering over a circle, check for boxes
                            var hoveredBox = drawingBoxes.where((box) {
                              var rect = Rect.fromLTWH(
                                box.box.rect.left *
                                    lastImageDestinationRect.width,
                                box.box.rect.top *
                                    lastImageDestinationRect.height,
                                box.box.rect.width *
                                    lastImageDestinationRect.width,
                                box.box.rect.height *
                                    lastImageDestinationRect.height,
                              );
                              return rect.contains(d.localPosition);
                            }).firstOrNull;

                            print("hoveredBox: $hoveredBox");

                            if (hoveredBox != null) {
                              // Hovering over a box (but not a circle)
                              widget.onHover(hoveredBox, null);
                            } else {
                              // Not hovering over anything
                              widget.onHover(null, null);
                            }
                            hoveredCircle = null;
                          }
                        },
                        child: CustomPaint(
                          foregroundPainter: ImageCirclesPainter(
                              selectedCircle: widget.selectedCircle,
                              image: image,
                              boxes: boxesOnlyInner),
                          child: imageProvider != null
                              ? Image(
                                  image: imageProvider!,
                                )
                              : Container(),
                        ),
                      ),
                    ),
                  )),
            );
          }),
        ),
      ],
    );
  }
}
