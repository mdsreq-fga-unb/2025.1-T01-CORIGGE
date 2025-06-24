import 'package:corigge/utils/utils.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

import '../../../../config/theme.dart';
import '../../../splash/domain/repositories/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
        color: const Color(0xFFF0EFEA), // Cor de fundo da página
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Seção "Corigge" e slogan
            _buildHeroSection(),
            const SizedBox(height: 40),

            // Seção "Principais Recursos"
            _buildFeaturesSection(),
            const SizedBox(height: 60),

            // Botão "Sign in with Google"
            _buildSignInButton(context),
            const SizedBox(height: 40),
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
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'TRANSFORME A CORREÇÃO DE GABARITOS EM UM PROCESSO RÁPIDO, AUTOMÁTICO E SEM ERROS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[700],
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
          width: 250,
          height: 250,
          margin: const EdgeInsets.only(right: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
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
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/images/logo_corigge.svg',
                height: 150,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
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
        color: Colors.white,
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
          Icon(icon, size: 40, color: Colors.brown[800]),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        var result = await AuthService.signInWithGoogle();

        result.fold((l) {
          Utils.showTopSnackBar(context, "Erro ao fazer login: $l",
              color: kError);
        }, (r) {
          context.go('/home');
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Cor de fundo do botão
        foregroundColor: Colors.black, // Cor do texto e ícone
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Para que o Row não ocupe toda a largura
        children: [
          // Ícone do Google. Você pode usar uma imagem SVG/PNG ou um ícone de pacote.
          // Exemplo com um Container e uma cor para simular o G do Google.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red, // Cor para simular o G
            ),
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'SIGN IN WITH GOOGLE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
