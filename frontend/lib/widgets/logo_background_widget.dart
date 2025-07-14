import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:corigge/config/size_config.dart';

class LogoBackgroundWidget extends StatelessWidget {
  const LogoBackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main logo in the center-top
        Positioned(
          left: MediaQuery.of(context).size.width * 0.25,
          top: MediaQuery.of(context).size.height * 0,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.25),
            child: SvgPicture.asset(
              'assets/images/logo_corigge.svg',
              height: getProportionateScreenHeight(300),
            ),
          ),
        ),
        // Left logo in the bottom area
        Positioned(
          left: MediaQuery.of(context).size.width * 0.25 -
              getProportionateScreenWidth(150),
          top: MediaQuery.of(context).size.height * 0.5 +
              getProportionateScreenHeight(50),
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: SvgPicture.asset(
              'assets/images/logo_corigge.svg',
              height: getProportionateScreenHeight(200),
            ),
          ),
        ),
        // Right logo in the bottom area
        Positioned(
          left: MediaQuery.of(context).size.width * 0.25 +
              getProportionateScreenWidth(120),
          top: MediaQuery.of(context).size.height * 0.5 +
              getProportionateScreenHeight(80),
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: SvgPicture.asset(
              'assets/images/logo_corigge.svg',
              height: getProportionateScreenHeight(220),
            ),
          ),
        ),
      ],
    );
  }
}
