import 'package:corigge/utils/utils.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:corigge/widgets/dropdown_search_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:brasil_fields/brasil_fields.dart';

import '../../../../config/theme.dart';
import '../../../../models/escola_model.dart';
import '../../../../services/escolas_service.dart';
import '../../../login/data/user_model.dart';
import '../../../splash/domain/repositories/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  EscolaModel? _selectedSchool;
  bool _isLoading = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  List<EscolaModel> _escolas = [];
  bool _isLoadingEscolas = false;
  String? _errorMessageEscolas;

  Future<bool> loadEscolas() async {
    if (_isLoadingEscolas) {
      return false;
    }

    _isLoadingEscolas = true;

    final result = await EscolasService.getEscolas();

    result.fold((error) {
      _errorMessageEscolas = error;
    }, (schools) {
      _escolas = schools;
    });

    return true;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text;
      _isEmailValid = email.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    });
  }

  void _validatePhone() {
    setState(() {
      final phone = _phoneController.text;
      _isPhoneValid = phone.isNotEmpty && phone.length >= 14; // (99) 99999-9999
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchool == null) {
      Utils.showTopSnackBar(
        context,
        "Por favor, selecione uma escola",
        color: kError,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = UserModel(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        idEscola: _selectedSchool!.id,
      );

      await AuthService.databaseInsertUser(user);

      if (mounted) {
        Utils.showTopSnackBar(
          context,
          "Registro realizado com sucesso!",
          color: kSuccess,
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        Utils.showTopSnackBar(
          context,
          "Erro ao registrar: $e",
          color: kError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(),
      body: FutureBuilder<bool>(
        future: loadEscolas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || _errorMessageEscolas != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar escolas: $_errorMessageEscolas'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Container(
              color: const Color(0xFFF0EFEA),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'CADASTRO',
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
                      'CRIE SUA CONTA PARA COMEÇAR A USAR O CORIGGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome Completo',
                              prefixIcon:
                                  Icon(Icons.person, color: Colors.brown[800]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.brown[800]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu nome';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon:
                                  Icon(Icons.email, color: Colors.brown[800]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.brown[800]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu e-mail';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Por favor, insira um e-mail válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TelefoneInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Telefone',
                              prefixIcon:
                                  Icon(Icons.phone, color: Colors.brown[800]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.brown[800]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              hintText: '(99) 99999-9999',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu telefone';
                              }
                              if (value.length < 14) {
                                return 'Por favor, insira um telefone válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownSearchCustom<EscolaModel>(
                            hintText: 'Escola',
                            prefixIcon: Icons.school,
                            items: _escolas,
                            selectedItem: _selectedSchool,
                            itemAsString: (escola) => escola.nome,
                            onChanged: (escola) => _selectedSchool = escola,
                            compareFn: (a, b) => a.id == b.id,
                          ),
                          if (_isEmailValid && _isPhoneValid) ...[
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[800],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'CADASTRAR',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta?',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Faça login',
                          style: TextStyle(
                            color: Colors.brown[800],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
