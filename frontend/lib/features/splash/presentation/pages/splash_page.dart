import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../services/opencv_service.dart';
import '../../../../widgets/app_bar_custom.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

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
      backgroundColor: kPrimary,
      body: 
           Center(
            child: SvgPicture.asset(
              "assets/images/logo_corigge.svg",
              height: 300,
            ))
    );
  }
}
