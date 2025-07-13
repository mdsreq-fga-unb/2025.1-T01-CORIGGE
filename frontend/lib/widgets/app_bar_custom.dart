import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/size_config.dart';
import '../config/theme.dart';
import '../features/splash/domain/repositories/auth_service.dart';
import 'default_button_widget.dart';

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

  static PreferredSizeWidget appBarWithLogo({
    void Function()? onWantsToGoBack,
  }) {
    return AppBar(
      leading: onWantsToGoBack != null
          ? Align(
              alignment: Alignment.center,
              child: topBackButtonWidget(onPressed: onWantsToGoBack))
          : Container(),
      leadingWidth: onWantsToGoBack != null ? null : 0,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          SizedBox(width: getProportionateScreenWidth(8)),
          Text(
            'Corigge',
            style: TextStyle(
              color: Colors.brown[800],
              fontSize: getProportionateFontSize(24),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        DefaultButtonWidget(
          expanded: false,
          onPressed: () {
            // Ação para o botão Sobre
          },
          color: kPrimary,
          child: Text(
            'Sobre',
            style: TextStyle(
                color: Colors.white, fontSize: getProportionateFontSize(16)),
          ),
        ),
        DefaultButtonWidget(
          expanded: false,
          onPressed: () {
            // Ação para o botão Contato
          },
          color: kPrimary,
          child: Text(
            'Contato',
            style: TextStyle(
                color: Colors.white, fontSize: getProportionateFontSize(16)),
          ),
        ),
        if (SharedPreferencesHelper.currentUser != null)
          Builder(
            builder: (context) => DefaultButtonWidget(
              expanded: false,
              onPressed: () {
                context.go('/profile');
              },
              color: kPrimary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person,
                      color: Colors.white,
                      size: getProportionateScreenWidth(20)),
                  SizedBox(width: getProportionateScreenWidth(4)),
                  Text(
                    'Perfil',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: getProportionateFontSize(16)),
                  ),
                ],
              ),
            ),
          ),
        if (SharedPreferencesHelper.currentUser != null)
          Builder(
            builder: (context) => DefaultButtonWidget(
              expanded: false,
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              color: kPrimary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout,
                      color: Colors.white,
                      size: getProportionateScreenWidth(20)),
                  SizedBox(width: getProportionateScreenWidth(4)),
                  Text(
                    'Sair',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: getProportionateFontSize(16)),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(width: getProportionateScreenWidth(16)),
      ],
    );
  }

  static Widget topBackButtonWidget({required Function() onPressed}) {
    return DefaultButtonWidget(
      onPressed: onPressed,
      color: Colors.transparent,
      width: getProportionateScreenWidth(40),
      height: getProportionateScreenHeight(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: kPrimary),
      ),
      child: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimary),
    );
  }
}
