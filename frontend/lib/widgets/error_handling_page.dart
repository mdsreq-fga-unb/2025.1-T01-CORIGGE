import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../cache/shared_preferences_helper.dart';
import '../config/size_config.dart';
import '../config/theme.dart';
import 'default_button_widget.dart';

class ErrorHandlingPage extends StatelessWidget {
  final Widget? child;
  final String? errorText;
  final bool showHomeButton;
  final String duckAsset;
  final bool shouldHaveChild;

  const ErrorHandlingPage(
      {super.key,
      this.duckAsset = "assets/images/logo_splash.png",
      required this.errorText,
      this.child,
      this.shouldHaveChild = false,
      this.showHomeButton = true});

  @override
  Widget build(BuildContext context) {
    return SharedPreferencesHelper.currentUser == null
        ? SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(12)),
              child: Column(
                children: [
                  Image.asset(
                    duckAsset,
                    height: getProportionateScreenHeight(300),
                  ),
                  if (duckAsset == "assets/images/logo_splash.png") ...[
                    const Text(
                      "Olá Patinho!, parece que você não está logado",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(10),
                    ),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(10)),
                      child: Text(errorText!),
                    ),
                  ],
                  if (showHomeButton)
                    SizedBox(
                      height: getProportionateScreenHeight(30),
                    ),
                  if (showHomeButton)
                    SizedBox(
                      width: getProportionateScreenWidth(150),
                      height: getProportionateScreenHeight(56),
                      child: DefaultButtonWidget(
                        onPressed: () {
                          context.go("/login");
                        },
                        child: const Text("Ir para Login",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          )
        : errorText != null
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(12)),
                  child: Column(
                    children: [
                      Image.asset(
                        duckAsset,
                        height: getProportionateScreenHeight(300),
                      ),
                      if (duckAsset == "assets/images/logo_splash.png") ...[
                        const Text(
                          "Ops algo deu errado!",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(10),
                        ),
                        Text(
                          errorText!,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kError,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(10)),
                          child: Text(errorText!),
                        ),
                      ],
                      if (showHomeButton)
                        SizedBox(
                          height: getProportionateScreenHeight(30),
                        ),
                      if (showHomeButton)
                        SizedBox(
                          width: getProportionateScreenWidth(150),
                          height: getProportionateScreenHeight(56),
                          child: DefaultButtonWidget(
                            onPressed: () {
                              context.go("/home");
                            },
                            child: const Text("Ir para Home",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (shouldHaveChild) ...[child ?? Container()]
                    ],
                  ),
                ),
              )
            : (child ?? Container());
  }
}
