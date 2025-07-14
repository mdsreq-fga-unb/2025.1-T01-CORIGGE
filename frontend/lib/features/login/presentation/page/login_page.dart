import 'package:corigge/utils/utils.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import 'package:corigge/services/auth_service_wrapper.dart'; // Importar o wrapper
import 'package:corigge/widgets/default_button_widget.dart';

class LoginPage extends StatelessWidget {
  final AuthServiceWrapper authServiceWrapper; // Adicionar como dependência

  const LoginPage({super.key, required this.authServiceWrapper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: kBackground, // Cor de fundo da página
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Seção "Corigge" e slogan
            _buildHeroSection(),
            SizedBox(height: getProportionateScreenHeight(40)),

            // Seção "Principais Recursos"
            _buildFeaturesSection(),
            SizedBox(height: getProportionateScreenHeight(60)),

            // Botão "Sign in with Google"
            _buildSignInButton(context),
            SizedBox(height: getProportionateScreenHeight(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Text(
          'CORIGGE',
          style: TextStyle(
            fontSize: getProportionateFontSize(48),
            fontWeight: FontWeight.bold,
            color: kOnBackground,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(16)),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(20.0)),
          child: Text(
            'TRANSFORME A CORREÇÃO DE GABARITOS EM UM PROCESSO RÁPIDO, AUTOMÁTICO E SEM ERROS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: getProportionateFontSize(22),
              color: kOnBackground.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side image
        Container(
          width: getProportionateScreenWidth(250),
          height: getProportionateScreenHeight(250),
          margin: EdgeInsets.only(right: getProportionateScreenWidth(40)),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: getProportionateScreenWidth(150),
              height: getProportionateScreenHeight(150),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/images/logo_corigge.svg',
                height: getProportionateScreenHeight(150),
              ),
            ),
          ),
        ),

        // Right side features grid
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRINCIPAIS RECURSOS',
                style: TextStyle(
                  fontSize: getProportionateFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: kOnBackground.withOpacity(0.7),
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    children: [
                      _buildFeatureCard(
                        icon: Icons.timer,
                        title: 'Correção Rápida',
                        description: '100 GABARITOS POR MINUTO',
                      ),
                      _buildFeatureCard(
                        icon: Icons.check_circle_outline,
                        title: 'Alta Precisão',
                        description: 'MAIS DE 99% DE PRECISÃO',
                      ),
                      _buildFeatureCard(
                        icon: Icons.bar_chart,
                        title: 'Relatórios Detalhados',
                        description: 'ANÁLISE DE DESEMPENHO COMPLETA',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: kPrimary),
          SizedBox(height: getProportionateScreenHeight(10)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: getProportionateFontSize(16),
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(5)),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: getProportionateFontSize(12),
              color: kOnBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return DefaultButtonWidget(
      onPressed: () async {
        var result = await authServiceWrapper.signInWithGoogle(); // Usar o wrapper

        result.fold((l) {
          if (l == 'User not found') {
            context.go('/registro');
            return;
          }
          Utils.showTopSnackBar(context, "Erro ao fazer login: $l",
              color: kError);
        }, (r) {
          context.go('/home');
        });
      },
      color: kSurface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getProportionateScreenWidth(24),
            height: getProportionateScreenHeight(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kError,
            ),
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: kSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(10)),
          Text(
            'SIGN IN WITH GOOGLE',
            style: TextStyle(
              fontSize: getProportionateFontSize(18),
              fontWeight: FontWeight.bold,
              color: kOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}
