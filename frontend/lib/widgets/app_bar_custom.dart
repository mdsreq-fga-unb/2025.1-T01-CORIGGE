import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../config/size_config.dart';
import '../config/theme.dart';

class AppBarCustom {
  static PreferredSizeWidget createAppBarWithBackButton(BuildContext context,
      {required void Function() onPressed,
      Color backgroundColor = Colors.transparent,
      List<Widget>? actions,
      SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle.light}) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      elevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      leading: Align(
          alignment: Alignment.center,
          child: topBackButtonWidget(onPressed: onPressed)),
      actions: actions,
    );
  }

  static PreferredSizeWidget createAppBarWithMenuButton(BuildContext context,
      {required Widget? leading,
      Color backgroundColor = Colors.transparent,
      SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle.light}) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      elevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      leading: leading,
    );
  }

  /// ***************************************************************************************
  ///
  /// When the app build is generated, the app bar becomes transparent and we need to inform
  ///
  /// ***************************************************************************************
  static PreferredSizeWidget invisibleAppBarWidget() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(0),
      child: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
      ),
    );
  }

  static Widget topBackButtonWidget({required Function() onPressed}) {
    return SizedBox(
      width: getProportionateScreenWidth(42),
      child: MaterialButton(
        highlightElevation: 0,
        height: getProportionateScreenWidth(41),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kPrimary),
        ),
        splashColor: Colors.transparent,
        color: Colors.transparent,
        elevation: 0,
        onPressed: onPressed,
        child: SvgPicture.asset(
          "assets/icons/arrow_back_icon.svg",
          fit: BoxFit.cover,
          // ignore: deprecated_member_use
          color: kPrimary,
        ),
      ),
    );
  }
}
