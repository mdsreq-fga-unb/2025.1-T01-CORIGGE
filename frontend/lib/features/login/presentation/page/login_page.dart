import 'package:corigge/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

import '../../../../config/theme.dart';
import '../../../splash/domain/repositories/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
      crossAxisAlignment: CrossAxisAlignment.start, // Alinha os itens ao topo
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Imagem do gabarito (à esquerda)
        Container(
          width: 250, // Ajuste o tamanho conforme necessário
          height: 250,
          decoration: BoxDecoration(
            color:
                const Color(0xFF8B4513), // Cor de fundo da imagem do gabarito
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
            child:
                // Você precisará de um ícone ou SVG customizado para isso.
                // Para simplificar, vou usar um Container temporário.
                Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment,
                  size: 80, color: Color(0xFF8B4513)),
            ),
          ),
        ),
        const SizedBox(width: 40), // Espaço entre a imagem e os cards

        // Cards dos recursos (à direita)
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      width: 200, // Ajuste o tamanho do card conforme necessário
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
