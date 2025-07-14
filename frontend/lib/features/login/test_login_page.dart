import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/services/auth_service_wrapper.dart';
import 'package:corigge/widgets/default_button_widget.dart';
import 'package:corigge/utils/utils.dart';
import 'package:corigge/utils/utils_wrapper.dart'; // Importar o wrapper

// Uma versão simplificada da LoginPage para testes
class TestLoginPage extends StatelessWidget {
  final AuthServiceWrapper authServiceWrapper;
  final UtilsWrapper utilsWrapper; // Adicionar como dependência

  const TestLoginPage({super.key, required this.authServiceWrapper, required this.utilsWrapper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DefaultButtonWidget(
          onPressed: () async {
            var result = await authServiceWrapper.signInWithGoogle();

            result.fold((l) {
              if (l == 'User not found') {
                context.go('/registro');
                return;
              }
              utilsWrapper.showTopSnackBar(context, "Erro ao fazer login: $l"); // Usar o wrapper
            }, (r) {
              context.go('/home');
            });
          },
          color: Colors.blue,
          child: const Text('SIGN IN WITH GOOGLE'),
        ),
      ),
    );
  }
}
