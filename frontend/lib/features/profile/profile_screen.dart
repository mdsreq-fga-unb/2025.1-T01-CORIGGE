import 'package:corigge/cache/shared_preferences_helper_wrapper.dart';
import 'package:corigge/config/size_config.dart';
import 'package:corigge/config/theme.dart';
import 'package:corigge/features/login/data/user_model.dart';
import 'package:corigge/services/auth_service_wrapper.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:corigge/services/escolas_service_wrapper.dart';
import 'package:corigge/utils/utils_wrapper.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:corigge/widgets/default_button_widget.dart';
import 'package:corigge/widgets/dropdown_search_custom.dart';
import 'package:corigge/widgets/logo_background_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final AuthServiceWrapper authServiceWrapper;
  final EscolasServiceWrapper escolasServiceWrapper;
  final SharedPreferencesHelperWrapper sharedPreferencesHelperWrapper;
  final UtilsWrapper utilsWrapper;

  const ProfileScreen({
    super.key,
    required this.authServiceWrapper,
    required this.escolasServiceWrapper,
    required this.sharedPreferencesHelperWrapper,
    required this.utilsWrapper,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  EscolaModel? _selectedSchool;
  bool _isLoading = false;
  bool _isNameValid = false;
  bool _isPhoneValid = false;
  List<EscolaModel> _escolas = [];
  bool _isLoadingEscolas = false;
  String? _errorMessageEscolas;
  UserModel? _currentUser;

  Future<bool> loadEscolas() async {
    if (_isLoadingEscolas) {
      return false;
    }

    _isLoadingEscolas = true;

    final result = await widget.escolasServiceWrapper.getEscolas();

    result.fold((error) {
      _errorMessageEscolas = error;
    }, (schools) {
      _escolas = schools;
      // Find and set the current school
      if (_currentUser?.idEscola != null) {
        try {
          _selectedSchool = _escolas
              .firstWhere((school) => school.id == _currentUser!.idEscola);
        } catch (e) {
          // School not found, keep null
        }
      }
    });

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
  }

  void _loadCurrentUser() {
    _currentUser = widget.sharedPreferencesHelperWrapper.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name ?? '';
      _phoneController.text = _currentUser!.phoneNumber ?? '';
      _validateName();
      _validatePhone();
    }
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }

  void _validatePhone() {
    setState(() {
      final phone = _phoneController.text;
      _isPhoneValid = phone.isNotEmpty && phone.length >= 14; // (99) 99999-9999
    });
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUser == null) {
      widget.utilsWrapper.showTopSnackBar(context, "Erro: usuário não encontrado",
          color: kError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        idEscola: _selectedSchool?.id,
      );

      final result = await widget.authServiceWrapper.databaseUpdateUser(updatedUser);

      result.fold(
        (error) {
          widget.utilsWrapper.showTopSnackBar(context, "Erro ao atualizar perfil: $error",
              color: kError);
        },
        (user) {
          widget.sharedPreferencesHelperWrapper.currentUser = user;
          setState(() => _currentUser = user);
          widget.utilsWrapper.showTopSnackBar(context, "Perfil atualizado com sucesso!",
              color: kSuccess);
        },
      );
    } catch (e) {
      widget.utilsWrapper.showTopSnackBar(context, "Erro ao atualizar perfil: $e",
          color: kError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await widget.authServiceWrapper.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(onWantsToGoBack: () {
        context.go('/home');
      }),
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

          return SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(32)),
              child: Row(
                children: [
                  // Left side with logo
                  const Expanded(
                    child: LogoBackgroundWidget(),
                  ),
                  // Right side with profile form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'MEU PERFIL',
                            style: TextStyle(
                              fontSize: getProportionateFontSize(24),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: getProportionateScreenHeight(20)),

                          // Email field (read-only)
                          Container(
                            padding:
                                EdgeInsets.all(getProportionateScreenWidth(16)),
                            decoration: BoxDecoration(
                              color: kSurface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: kOnSurface.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.email,
                                    color: kOnSurface.withOpacity(0.7)),
                                SizedBox(
                                    width: getProportionateScreenWidth(12)),
                                Expanded(
                                  child: Text(
                                    _currentUser?.email ??
                                        'Email não disponível',
                                    style: TextStyle(
                                      fontSize: getProportionateFontSize(16),
                                      color: kOnSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),

                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, insira seu nome completo';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),

                          // Phone field
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Telefone',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, insira seu telefone';
                              }
                              if (value.length < 14) {
                                return 'Telefone deve ter pelo menos 14 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),

                          // School dropdown
                          DropdownButtonFormField<EscolaModel>(
                            value: _selectedSchool,
                            decoration: InputDecoration(
                              labelText: 'Escola',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _escolas.map((escola) {
                              return DropdownMenuItem<EscolaModel>(
                                value: escola,
                                child: Text(escola.nome),
                              );
                            }).toList(),
                            onChanged: (EscolaModel? value) {
                              setState(() {
                                _selectedSchool = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor, selecione uma escola';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: getProportionateScreenHeight(30)),

                          // Save button
                          DefaultButtonWidget(
                            onPressed: _isLoading ? null : _handleUpdateProfile,
                            color: kSecondaryVariant,
                            child: _isLoading
                                ? SizedBox(
                                    height: getProportionateScreenHeight(20),
                                    width: getProportionateScreenWidth(20),
                                    child: CircularProgressIndicator(
                                      color: kSurface,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'SALVAR ALTERAÇÕES',
                                    style: TextStyle(
                                      fontSize: getProportionateFontSize(18),
                                      color: kSurface,
                                    ),
                                  ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(20)),

                          // Logout button
                          DefaultButtonWidget(
                            onPressed: _handleLogout,
                            color: kError,
                            child: Text(
                              'SAIR',
                              style: TextStyle(
                                fontSize: getProportionateFontSize(18),
                                color: kSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
