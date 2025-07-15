import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cache/shared_preferences_helper.dart';
import '../config/size_config.dart';
import '../config/theme.dart';
import '../widgets/default_button_widget.dart';
import '../widgets/selectable_button_widget.dart';
import '../features/templates/data/answer_sheet_identifiable_box.dart';
import 'image_bounding_box/data/box_details.dart';
import 'image_bounding_box/data/image_circle.dart';

class MinMaxPair<T extends num> {
  final T min;
  final T max;

  MinMaxPair(this.min, this.max);
}

class Pair<T, U> {
  final T first;
  final U second;

  Pair(this.first, this.second);
}

class RangeTextInputFormatter extends TextInputFormatter {
  final double lowerBound;
  final double upperBound;
  final int decimalPlaces;

  RangeTextInputFormatter({
    this.lowerBound = 0.0,
    this.upperBound = 100.0,
    this.decimalPlaces = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue; // allows deleting everything
    }

    // Special case: Allow input if the only character is "-"
    if (lowerBound < 0 && newValue.text == '-') {
      return newValue;
    }

    final double? newVal = double.tryParse(newValue.text);
    if (newVal == null ||
        newVal > upperBound ||
        newVal < lowerBound ||
        !_isValidDecimalPlaces(newValue.text)) {
      return oldValue; // rejects non-valid floating points and values out of range
    }

    return newValue; // allows anything else
  }

  bool _isValidDecimalPlaces(String text) {
    // Adjust the regex to allow an optional negative sign only if lowerBound < 0
    String pattern = lowerBound < 0
        ? r'^-?\d+(\.\d{0,DECIMAL_PLACES})?$'
        : r'^\d+(\.\d{0,DECIMAL_PLACES})?$';

    final regExp =
        RegExp(pattern.replaceAll('DECIMAL_PLACES', decimalPlaces.toString()));

    return regExp.hasMatch(text);
  }
}

class StringWithAssociatedID {
  int id;
  String text;

  StringWithAssociatedID({this.id = -1, this.text = ""});
}

class Utils {
  static final encrypt.Key _encryptDecryptKey =
      encrypt.Key.fromBase64("aWhTZlWhBiduT0vPuT8pvQ==");
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_encryptDecryptKey));
  static final _iv = encrypt.IV.fromUtf8("aWhTZlWhBiduT0vP");

  static String formatDate(DateTime date, {bool usDate = false}) {
    if (usDate) {
      return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}";
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  static String formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  static String formatDateTime(DateTime date, {bool usDate = false}) {
    return "${formatDate(date, usDate: usDate)} às ${formatTime(date)}";
  }

  static String removeEverythingBetweenGreaterThanAndLessThan(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static bool doesTestNameHaveLinguaEstrangeira(String textName) {
    const linguasEstrangeiras = ["Inglês", "Espanhol", "Francês"];

    return linguasEstrangeiras.any((element) => textName.contains(element));
  }

  static bool doesTestNameHaveLinguaEstrangeiraErrada(String textName) {
    const linguasEstrangeiras = ["INGLÊS", "ESPANHOL", "FRANCÊS"];

    return linguasEstrangeiras.any((element) => textName.contains(element));
  }

  static void showTopSnackBar(
    BuildContext context,
    String message, {
    Color? color,
    Duration? duration,
  }) {
    if (!context.mounted) {
      print("Context not mounted, skipping snackbar");
      return;
    }

    final backgroundColor = kPrimary;

    Flushbar(
      onTap: (flushbar) {
        flushbar.dismiss();
      },
      message: message,
      margin: EdgeInsets.all(getProportionateScreenWidth(8)),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: color ?? backgroundColor,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      isDismissible: false,
    ).show(context);
  }

  static String normalizePortugueseTextLower(String text) {
    return text
        .toLowerCase()
        .replaceAll("á", "a")
        .replaceAll("ã", "a")
        .replaceAll("â", "a")
        .replaceAll("à", "a")
        .replaceAll("é", "e")
        .replaceAll("ê", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("ô", "o")
        .replaceAll("õ", "o")
        .replaceAll("ú", "u")
        .replaceAll("ç", "c")
        .trim();
  }

  static String getDayOfWeek(int day) {
    switch (day) {
      case 0:
        return "Domingo";
      case 1:
        return "Segunda";
      case 2:
        return "Terça";
      case 3:
        return "Quarta";
      case 4:
        return "Quinta";
      case 5:
        return "Sexta";
      case 6:
        return "Sábado";
      case 7:
        return "Domingo";
      default:
        return "";
    }
  }

  static String getMonthNameSmall(int month) {
    switch (month) {
      case 1:
        return "Jan";
      case 2:
        return "Fev";
      case 3:
        return "Mar";
      case 4:
        return "Abr";
      case 5:
        return "Mai";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Ago";
      case 9:
        return "Set";
      case 10:
        return "Out";
      case 11:
        return "Nov";
      case 12:
        return "Dez";
      default:
        return "";
    }
  }

  static String base64UrlSafeEncode(String input) {
    var base64String = input.replaceAll('+', '_').replaceAll('/', '-');

    return base64String;
  }

  static String base64UrlSafeDecode(String input) {
    // Substitui os caracteres para o formato Base64 padrão
    String base64String = input.replaceAll('-', '/').replaceAll('_', '+');

    return base64String;
  }

  static String encryptString(String toEncrypt) {
    final encrypted = _encrypter.encrypt(toEncrypt, iv: _iv);
    String encryptedBase64UrlSafe = base64UrlSafeEncode(encrypted.base64);
    return encryptedBase64UrlSafe;
  }

  static String decryptString(String toDecrypt) {
    toDecrypt = base64UrlSafeDecode(toDecrypt);
    final decrypted = _encrypter.decrypt64(toDecrypt, iv: _iv);
    return decrypted;
  }

  static void copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
  }

  static bool isNumberCloseToInt(double number, double variation) {
    return number > number.roundToDouble() - variation &&
        number < number.roundToDouble() + variation;
  }

  static bool isNumberCloseTo(double number, double closeTo, double variation) {
    return number > closeTo - variation && number < closeTo + variation;
  }

  static bool validateEmail(String email) {
    final RegExp regex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\s*$");
    return regex.hasMatch(email);
  }

  static calculatePercentage(double progress, double total) {
    if (total == 0.0) {
      return 0.0;
    }
    return (progress / total) * 100;
  }

  static String capitalize(String text) {
    return text.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return '';
    }).join(' ');
  }

  static DateTime startOfWeek(DateTime date) {
    // Calculate the difference from Monday
    int daysFromMonday = date.weekday - DateTime.monday;
    // Subtract the difference to get to the start of the week
    return DateTime(date.year, date.month, date.day - daysFromMonday)
        .add(const Duration(minutes: 1));
  }

  static DateTime startOfDay(DateTime date) {
    date = date.toLocal();

    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfWeek(DateTime date) {
    // Calculate the difference to Sunday
    int daysToSunday = DateTime.sunday - date.weekday;
    // Add the difference to get to the end of the week
    return DateTime(
        date.year, date.month, date.day + daysToSunday, 23, 59, 59, 999);
    // This sets the time to the last millisecond of the day, representing the end of the week.
  }

  static T? randomChoiceFromList<T>(List<T> list) {
    if (list.isEmpty) {
      return null;
    }

    return list[Random().nextInt(list.length)];
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final hex = includeAlpha
        ? '#${color.value.toRadixString(16).padLeft(8, '0')}'
        : '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
    return hex;
  }

  static String colorToCSS(Color color) {
    return "#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}";
  }

  static bool hasNewWeekStarted(DateTime date1, DateTime date2) {
    DateTime startOfWeekDate1 = startOfWeek(date1);
    DateTime startOfWeekDate2 = startOfWeek(date2);

    return !startOfWeekDate1.isAtSameMomentAs(startOfWeekDate2);
  }

  static String hashString(String text) {
    var bytes1 = utf8.encode(text); // data being hashed
    var digest1 = sha256.convert(bytes1);

    return digest1.toString();
  }

  static Widget createGeneralLoadingPage(
      {required String text, required Future<bool> Function() futureFunction}) {
    return Scaffold(
      backgroundColor: kBackground,
      body: FutureBuilder(
        future: futureFunction(),
        builder: (context, snapshot) {
          return Column(children: [
            Image.asset(
              "assets/img/pato-meditando.png",
              height: getProportionateScreenHeight(150),
            ),
            Text(
              text,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: getProportionateFontSize(20)),
            ),
            const CircularProgressIndicator()
          ]);
        },
      ),
    );
  }

  static Future<void> showLoadingDialog(BuildContext context,
      {String? text,
      void Function(void Function(String))? updatingTextFunction}) async {
    await showDuckDialog(
      context,
      "assets/img/pato-megafone.png",
      barrierDismissable: false,
      child: LoadingDialogContent(
        initialText: text,
        updatingTextFunction: updatingTextFunction,
      ),
    );
  }

  static void showMultipleChoiceDialog(BuildContext context,
      {required List<StringWithAssociatedID> options,
      void Function(StringWithAssociatedID)? onSelected,
      required String title}) {
    showDialog(
        useSafeArea: false,
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: TapRegion(
                onTapOutside: (_) {
                  Navigator.of(context).pop();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: getProportionateScreenHeight(100),
                      child: Container(
                        width: (isDesktop() ? 600 : 350),
                        decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: kPrimary,
                                width: getProportionateScreenWidth(2))),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(20),
                              vertical: getProportionateScreenHeight(20)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: getProportionateFontSize(20),
                                    color: kSurface),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),
                              ListView.separated(
                                  shrinkWrap: true,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(12),
                                      ),
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    return SelectableButtonWidget(
                                        borderRadius: 5,
                                        height:
                                            getProportionateScreenHeight(46),
                                        onPressed: (s) {
                                          Navigator.of(context).pop();
                                          onSelected?.call(options[index]);
                                        },
                                        selected: false,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            options[index].text,
                                            style: TextStyle(
                                                fontSize:
                                                    getProportionateFontSize(
                                                        16),
                                                color: kSurface),
                                            textAlign: TextAlign.left,
                                          ),
                                        ));
                                  }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
        });
  }

  static Future<void> showDuckDialog(BuildContext context, String duckAsset,
      {required Widget child,
      double? containerOffset,
      double? duckSize,
      double? containerWidth,
      double topOffset = 100,
      VoidCallback? onTapOutside,
      bool barrierDismissable = true,
      bool onTopOfIframe = false}) async {
    containerOffset ??= isDesktop() ? 0.8 : 0.6;
    duckSize ??= isDesktop() ? 300 : 200;
    await showDialog(
        useSafeArea: false,
        context: context,
        barrierDismissible: barrierDismissable,
        builder: (context) {
          return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: getProportionateScreenHeight(
                        (duckSize! * containerOffset!) + topOffset),
                    child: TapRegion(
                      onTapOutside: (_) {
                        if (barrierDismissable) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: getProportionateScreenWidth(
                            containerWidth ?? (isDesktop() ? 600 : 300)),
                        decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(40)),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              4,
                              getProportionateScreenHeight(
                                  duckSize * (1 - containerOffset) +
                                      (isDesktop() ? 0 : -30)),
                              4,
                              8),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topOffset,
                    child: Image.asset(
                      duckAsset,
                      height: getProportionateScreenHeight(duckSize),
                    ),
                  ),
                ],
              ));
        });
  }

  static String generateRandomHexString(int length) {
    var random = Random();
    var values = List<int>.generate(length, (i) => random.nextInt(16));
    return values.map((e) => e.toRadixString(16)).join();
  }

  static String getBoxNameByLabel(AnswerSheetIdentifiableBox box) {
    switch (box.box.label) {
      case BoxDetailsType.matricula:
        return "Matrícula";
      case BoxDetailsType.exemploCirculo:
        return "Exemplo de Círculo";
      case BoxDetailsType.colunaDeQuestoes:
        return "Coluna de Questões";
      case BoxDetailsType.outro:
        return "Outro";
      default:
        return "Desconhecido";
    }
  }

  static Map<String, String> getAnswerFromCardBox(
      {required AnswerSheetIdentifiableBox box,
      required List<ImageCircle> circlesPerBox,
      required List<Map<String, String>> headersToGetSorted,
      required double tolerance}) {
    if (box.box.label == BoxDetailsType.matricula ||
        box.box.label == BoxDetailsType.typeB ||
        box.box.label == BoxDetailsType.outro) {
      int valor = 0;
      var columns = List<List<ImageCircle>>.from([]);

      var columnsMap = Map<double, List<ImageCircle>>.from({});

      for (var circle in circlesPerBox) {
        // find the closest column to the circle

        var closestColumn = columnsMap.keys
            .where((element) => (element - circle.center.dx).abs() < tolerance)
            .firstOrNull;

        if (closestColumn == null) {
          columnsMap[circle.center.dx] = [circle];
        } else {
          columnsMap[closestColumn]!.add(circle);
        }
      }

      var columnMapKeys = columnsMap.keys.toList()..sort();

      for (var key in columnMapKeys) {
        var column = columnsMap[key]!;

        column.sort((a, b) => a.center.dy.compareTo(b.center.dy));

        columns.add(column);
      }

      if (box.box.label == BoxDetailsType.matricula) {
        columns.removeWhere((element) =>
            element.fold(false,
                (previousValue, element) => previousValue || element.filled) ==
            false);
      } else if (box.box.label == BoxDetailsType.typeB) {
        var emptyCount = columns.where((element) =>
            element.fold(false,
                (previousValue, element) => previousValue || element.filled) ==
            false);
        if (emptyCount.isNotEmpty) {
          if (emptyCount.length > 1 && emptyCount.length != 3) {
            return {headersToGetSorted.first.keys.first: "INV"};
          } else {
            return {headersToGetSorted.first.keys.first: "NP"};
          }
        }
      }

      for (var columnEntry in columns.reversed.indexed) {
        var column = columnEntry.$2;
        var index = columnEntry.$1;

        bool foundForColumn = false;
        for (var line in column.indexed) {
          if (line.$2.filled) {
            if (foundForColumn) {
              if (box.box.label == BoxDetailsType.matricula) {
                return {"Matricula": List.generate(8, (index) => "0").join("")};
              } else {
                return {headersToGetSorted.first.keys.first: "INV"};
              }
            }

            if (box.box.label == BoxDetailsType.outro) {
              return {
                headersToGetSorted.first.keys.first: Uri.decodeComponent(
                    headersToGetSorted.first.values.first.split("_")[line.$1])
              };
            }

            valor += (line.$1) * (pow(10, index).toInt());
            foundForColumn = true;
          }
        }

        if (!foundForColumn) {
          if (box.box.label == BoxDetailsType.outro) {
            return {headersToGetSorted.first.keys.first: "Não preenchido"};
          }
        }
      }
      if (box.box.label == BoxDetailsType.matricula) {
        return {"Matricula": valor.toString()};
      }
      return {headersToGetSorted.first.keys.first: valor.toString()};
    } else {
      var questions = List<String>.from([]);

      var linesMap = Map<double, List<ImageCircle>>.from({});

      for (var circle in circlesPerBox) {
        // find the closest line to the circle

        var closestLine = linesMap.keys
            .where((element) => (element - circle.center.dy).abs() < tolerance)
            .firstOrNull;

        if (closestLine == null) {
          linesMap[circle.center.dy] = [circle];
        } else {
          linesMap[closestLine]!.add(circle);
        }
      }

      var linesMapKeys = linesMap.keys.toList()..sort();

      for (var key in linesMapKeys) {
        var line = linesMap[key]!;

        line.sort((a, b) => a.center.dx.compareTo(b.center.dx));

        if (line.length == 2) {
          if (line[0].filled && line[1].filled) {
            questions.add("INV");
          } else if (line[0].filled) {
            questions.add("C");
          } else if (line[1].filled) {
            questions.add("E");
          } else {
            questions.add("NP");
          }
        } else if (line.length == 4 || line.length == 5) {
          var bolinhasPreenchidas = line.fold(
              0,
              (previousValue, element) =>
                  previousValue + (element.filled ? 1 : 0));
          if (bolinhasPreenchidas != 1) {
            if (bolinhasPreenchidas == 0) {
              questions.add("NP");
            } else {
              questions.add("INV");
            }
          } else {
            questions.add([
              "A",
              "B",
              "C",
              "D",
              if (line.length == 5) "E"
            ][line.indexWhere((element) => element.filled)]);
          }
        } else {
          questions.add("ERROR");
        }
      }

      return Map.fromEntries(questions.indexed.map((e) {
        return MapEntry(headersToGetSorted[e.$1].keys.first, e.$2);
      }));
    }
  }

  static List<String> getEncodedLabels(AnswerSheetIdentifiableBox box) {
    final name = box.name;
    if (!name.contains('|')) return [];
    return name.split('|').skip(1).toList();
  }

  static void showGeneralAlertDialog(
      {required BuildContext context,
      required String text,
      VoidCallback? onAccept,
      bool onAcceptClose = true,
      VoidCallback? onCancel,
      bool importantDecision = false,
      bool onTopOfIframe = false,
      String continueText = "Ok",
      String cancelText = "Cancelar",
      double? buttonHeight,
      bool canCancel = true,
      TextStyle? textStyle,
      TextStyle? topTextStyle,
      String duckAsset = "assets/img/pato-confuso.png"}) {
    showDuckDialog(
      context,
      duckAsset,
      barrierDismissable: !importantDecision,
      onTapOutside: () {
        if (importantDecision) {
          return;
        }
        onCancel?.call();
      },
      containerOffset: 0.5,
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: topTextStyle ??
                TextStyle(
                    color: kSurface, fontSize: getProportionateFontSize(16)),
          ),
          SizedBox(
            height: getProportionateScreenHeight(20),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Visibility(
                  visible: canCancel,
                  child: Expanded(
                    flex: 10,
                    child: DefaultButtonWidget(
                      height: buttonHeight ?? getProportionateScreenHeight(36),
                      color: kError,
                      child: Text(
                        cancelText,
                        style:
                            textStyle ?? const TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: canCancel,
                  child: const Expanded(
                    child: SizedBox(),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: DefaultButtonWidget(
                    height: buttonHeight ?? getProportionateScreenHeight(36),
                    color: kSecondary,
                    child: Text(
                      continueText,
                      style: textStyle ?? const TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      if (onAcceptClose) {
                        Navigator.of(context).pop();
                      }
                      onAccept?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String formatTimeDifference(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours - days * 24;
    int minutes = duration.inMinutes - days * 24 * 60 - hours * 60;
    int seconds = duration.inSeconds -
        days * 24 * 60 * 60 -
        hours * 60 * 60 -
        minutes * 60;

    if (days > 0) {
      return "$days dias, $hours horas, $minutes minutos, $seconds segundos";
    } else if (hours > 0) {
      return "$hours horas, $minutes minutos, $seconds segundos";
    } else if (minutes > 0) {
      return "$minutes minutos, $seconds segundos";
    }
    return "$seconds segundos";
  }

  static void showGeneralNotificationDialog(
      {required BuildContext context,
      required String text,
      Future<void>? Function()? onAccept,
      bool onAcceptClose = true,
      VoidCallback? onCancel,
      bool importantDecision = false,
      bool onTopOfIframe = false,
      String continueText = "Ok",
      String cancelText = "Cancelar",
      double? buttonHeight,
      bool canCancel = true,
      ScrollController? scrollcontroller,
      TextStyle? textStyle,
      String duckAsset = "assets/img/pato-megafone.png"}) {
    showDuckDialog(
      context,
      duckAsset,
      topOffset: getProportionateScreenHeight(20),
      barrierDismissable: !importantDecision,
      onTapOutside: () {
        if (importantDecision) {
          return;
        }
        onCancel?.call();
      },
      containerOffset: 0.5,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(30)),
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width -
                  getProportionateScreenWidth(150),
              height: isDesktop()
                  ? getProportionateScreenHeight(500)
                  : getProportionateScreenHeight(450),
              child: Text(
                text,
                style: TextStyle(
                    color: kSurface, fontSize: getProportionateFontSize(16)),
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(5),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Visibility(
                    visible: canCancel,
                    child: Expanded(
                      flex: 10,
                      child: DefaultButtonWidget(
                        height:
                            buttonHeight ?? getProportionateScreenHeight(36),
                        color: kError,
                        child: Text(
                          cancelText,
                          style:
                              textStyle ?? const TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCancel?.call();
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: canCancel,
                    child: const Expanded(
                      child: SizedBox(),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: DefaultButtonWidget(
                      height: buttonHeight ?? getProportionateScreenHeight(36),
                      color: kSecondary,
                      child: Text(
                        continueText,
                        style:
                            textStyle ?? const TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (onAcceptClose) {
                          Navigator.of(context).pop();
                        }
                        await onAccept?.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingDialogContent extends StatefulWidget {
  final String? initialText;
  final void Function(void Function(String))? updatingTextFunction;

  const LoadingDialogContent(
      {super.key, this.initialText, this.updatingTextFunction});

  @override
  State<LoadingDialogContent> createState() => _LoadingDialogContentState();
}

class _LoadingDialogContentState extends State<LoadingDialogContent> {
  late String text;

  @override
  void initState() {
    super.initState();
    text = widget.initialText ?? "Carregando...";
    widget.updatingTextFunction?.call((String newText) {
      setState(() {
        text = newText;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(text),
          SizedBox(
            height: getProportionateScreenHeight(10),
          ),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
