import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/app_bar_custom.dart';
import '../../../../widgets/default_button_widget.dart';

class SplashPage extends StatefulWidget {
  final String? loadingStatus;
  final bool isError;

  const SplashPage({
    super.key,
    this.loadingStatus,
    this.isError = false,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarCustom.invisibleAppBarWidget(),
      backgroundColor: kSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loadingStatus != null) ...[
              if (!widget.isError)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kSurface),
                ),
              if (!widget.isError)
                SizedBox(height: getProportionateScreenHeight(16)),
              Text(
                widget.loadingStatus ?? 'Carregando...',
                style: TextStyle(fontSize: getProportionateFontSize(16)),
              ),
              if (widget.isError) ...[
                SizedBox(height: getProportionateScreenHeight(16)),
                DefaultButtonWidget(
                  onPressed: () {
                    context.go('/login');
                  },
                  color: kSurface,
                  child: Text(
                    'Tentar Novamente',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
            SvgPicture.asset(
              "assets/images/logo_corigge.svg",
              height: getProportionateScreenHeight(300),
            ),
          ],
        ),
      ),
    );
  }
}
