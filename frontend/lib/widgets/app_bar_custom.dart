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

  static PreferredSizeWidget appBarWithLogo() {
    return AppBar(
      backgroundColor: Colors.white, // Ou a cor de fundo da sua AppBar
      elevation: 0, // Sem sombra para a AppBar
      title: Row(
        children: [
          // Ícone ou imagem do logo Corrigge
          // Para um ícone simples:
          // Icon(Icons.check_circle_outline, color: Colors.brown[800]),
          // Ou para uma imagem do logo:
          // Image.asset('assets/images/corrigge_logo.png', height: 30),
          const SizedBox(width: 8),
          Text(
            'Corigge',
            style: TextStyle(
              color: Colors.brown[800],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Ação para o botão Sobre
          },
          child: Text(
            'Sobre',
            style: TextStyle(color: Colors.brown[800], fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () {
            // Ação para o botão Contato
          },
          child: Text(
            'Contato',
            style: TextStyle(color: Colors.brown[800], fontSize: 16),
          ),
        ),
        const SizedBox(width: 16),
      ],
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
