import 'package:corigge/config/size_config.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/config/theme.dart';
import 'package:corigge/widgets/default_button_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            children: [
              // Left side with logo
              Expanded(
                child: Builder(builder: (context) {
                  return Stack(
                    children: [
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.25,
                        top: MediaQuery.of(context).size.height * 0,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0.25),
                          child: SvgPicture.asset(
                            'assets/images/logo_corigge.svg',
                            height: 300,
                          ),
                        ),
                      ),
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.25 -
                            getProportionateScreenWidth(150),
                        top: MediaQuery.of(context).size.height * 0.5 +
                            getProportionateScreenHeight(50),
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: SvgPicture.asset(
                            'assets/images/logo_corigge.svg',
                            height: 200,
                          ),
                        ),
                      ),
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.25 +
                            getProportionateScreenWidth(120),
                        top: MediaQuery.of(context).size.height * 0.5 +
                            getProportionateScreenHeight(80),
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: SvgPicture.asset(
                            'assets/images/logo_corigge.svg',
                            height: 220,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              // Right side with buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ESCOLHA UM TEMPLATE DE CARTÃO-RESPOSTA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    DefaultButtonWidget(
                      onPressed: () {
                        context.go('/templates');
                      },
                      color: kSecondaryVariant,
                      child: Text(
                        'CRIAR GABARITO',
                        style: TextStyle(
                          fontSize: 18,
                          color: kSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'INSIRA OS CARTÕES-RESPOSTA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    DefaultButtonWidget(
                      onPressed: () {
                        context.go('/analyze-cards');
                      },
                      color: kSecondaryVariant,
                      child: Text(
                        'CORRIGIR CARTÕES',
                        style: TextStyle(
                          fontSize: 18,
                          color: kSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
