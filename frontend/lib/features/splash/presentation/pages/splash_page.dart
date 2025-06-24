import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../widgets/app_bar_custom.dart';

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
      backgroundColor: kPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loadingStatus != null) ...[
              if (!widget.isError)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              if (!widget.isError) const SizedBox(height: 16),
              Text(
                widget.loadingStatus!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isError) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimary,
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ],
            SvgPicture.asset(
              "assets/images/logo_corigge.svg",
              height: 300,
            ),
          ],
        ),
      ),
    );
  }
}
