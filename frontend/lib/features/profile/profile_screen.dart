import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:corigge/config/size_config.dart';
import 'package:corigge/config/theme.dart';
import 'package:corigge/features/login/data/user_model.dart';
import 'package:corigge/features/splash/domain/repositories/auth_service.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:corigge/services/escolas_service.dart';
import 'package:corigge/utils/utils.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:corigge/widgets/default_button_widget.dart';
import 'package:corigge/widgets/dropdown_search_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadEscolas();
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
  }

  void _loadCurrentUser() {
    _currentUser = SharedPreferencesHelper.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name ?? '';
      _phoneController.text = _currentUser!.phoneNumber ?? '';
      _validateName();
      _validatePhone();
    }
  }

  Future<void> _loadEscolas() async {
    setState(() => _isLoadingEscolas = true);

    final result = await EscolasService.getEscolas();

    result.fold(
      (error) {
        Utils.showTopSnackBar(context, "Erro ao carregar escolas: $error",
            color: kError);
      },
      (schools) {
        setState(() {
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
      },
    );

    setState(() => _isLoadingEscolas = false);
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
      Utils.showTopSnackBar(context, "Erro: usuário não encontrado",
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

      final result = await AuthService.databaseUpdateUser(updatedUser);

      result.fold(
        (error) {
          Utils.showTopSnackBar(context, "Erro ao atualizar perfil: $error",
              color: kError);
        },
        (user) {
          SharedPreferencesHelper.currentUser = user;
          setState(() => _currentUser = user);
          Utils.showTopSnackBar(context, "Perfil atualizado com sucesso!",
              color: kSuccess);
        },
      );
    } catch (e) {
      Utils.showTopSnackBar(context, "Erro ao atualizar perfil: $e",
          color: kError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
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
      appBar: AppBarCustom.appBarWithLogo(),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(32)),
          child: Row(
            children: [
              // Left side with logo
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.25,
                      top: MediaQuery.of(context).size.height * 0,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0.25),
                        child: SvgPicture.asset(
                          'assets/images/logo_corigge.svg',
                          height: getProportionateScreenHeight(300),
                        ),
                      ),
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.25 -
                          getProportionateScreenWidth(150),
                      top: MediaQuery.of(context).size.height * 0.5 +
                          getProportionateScreenHeight(50),
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: SvgPicture.asset(
                          'assets/images/logo_corigge.svg',
                          height: getProportionateScreenHeight(200),
                        ),
                      ),
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.25 +
                          getProportionateScreenWidth(120),
                      top: MediaQuery.of(context).size.height * 0.5 +
                          getProportionateScreenHeight(80),
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: SvgPicture.asset(
                          'assets/images/logo_corigge.svg',
                          height: getProportionateScreenHeight(220),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          border:
                              Border.all(color: kOnSurface.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email,
                                color: kOnSurface.withOpacity(0.7)),
                            SizedBox(width: getProportionateScreenWidth(12)),
                            Expanded(
                              child: Text(
                                _currentUser?.email ?? 'Email não disponível',
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
      ),
    );
  }
}
