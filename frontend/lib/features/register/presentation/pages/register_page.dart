import 'package:corigge/utils/utils.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:corigge/widgets/dropdown_search_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:brasil_fields/brasil_fields.dart';

import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../../../models/escola_model.dart';
import '../../../../services/escolas_service.dart';
import '../../../login/data/user_model.dart';
import '../../../splash/domain/repositories/auth_service.dart';
import 'package:corigge/widgets/default_button_widget.dart';

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
  bool _isNameValid = false;
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
    _nameController.addListener(_validateName);
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
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

  String _getMissingFieldsText() {
    List<String> missingFields = [];

    if (!_isNameValid) missingFields.add('nome');
    if (!_isEmailValid) missingFields.add('e-mail válido');
    if (!_isPhoneValid) missingFields.add('telefone');
    if (_selectedSchool == null) missingFields.add('escola');

    if (missingFields.isEmpty) return '';

    return 'Falta preencher: ${missingFields.join(', ')}';
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
        context.push('/login');
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
              color: kBackground,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: getProportionateScreenHeight(16)),
                  Text(
                    'Registrar',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(48),
                      fontWeight: FontWeight.bold,
                      color: kOnBackground,
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(20)),
                    child: Text(
                      'Crie sua conta para acessar o sistema de correção automática.',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(22),
                        color: kOnBackground.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(40)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: getProportionateScreenWidth(500)),
                    child: Container(
                      padding: EdgeInsets.all(getProportionateScreenWidth(24)),
                      decoration: BoxDecoration(
                        color: kSurface,
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
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nome Completo',
                                prefixIcon: Icon(Icons.person, color: kPrimary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: kPrimary),
                                ),
                                filled: true,
                                fillColor: kBackground.withOpacity(0.05),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, insira seu nome completo';
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
                                prefixIcon: Icon(Icons.email, color: kPrimary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: kPrimary),
                                ),
                                filled: true,
                                fillColor: kBackground.withOpacity(0.05),
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
                                prefixIcon: Icon(Icons.phone, color: kPrimary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color:
                                          kSecondaryVariant.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: kPrimary),
                                ),
                                filled: true,
                                fillColor: kBackground.withOpacity(0.05),
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
                              onChanged: (escola) {
                                _selectedSchool = escola;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {});
                                });
                              },
                              compareFn: (a, b) => a.id == b.id,
                            ),
                            const SizedBox(height: 20),
                            if (_getMissingFieldsText().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _getMissingFieldsText(),
                                  style: TextStyle(
                                    color: kOnBackground,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_isEmailValid &&
                                _isPhoneValid &&
                                _isNameValid &&
                                _selectedSchool != null) ...[
                              const SizedBox(height: 30),
                              DefaultButtonWidget(
                                onPressed: _isLoading ? null : _handleRegister,
                                disabled: _isLoading,
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
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta?',
                        style: TextStyle(
                          color: kOnBackground.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      DefaultButtonWidget(
                        onPressed: () => context.push('/login'),
                        color: Colors.transparent,
                        child: Text(
                          'Faça login',
                          style: TextStyle(
                            color: kPrimary,
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
