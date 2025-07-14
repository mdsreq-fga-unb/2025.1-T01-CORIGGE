import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/cache/shared_preferences_helper_wrapper.dart';
import 'package:corigge/features/login/data/user_model.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:corigge/services/auth_service_wrapper.dart';
import 'package:corigge/services/escolas_service_wrapper.dart';
import 'package:corigge/utils/utils_wrapper.dart';
import 'package:corigge/widgets/default_button_widget.dart';
import 'package:dartz/dartz.dart' hide State; // Esconder State do dartz

// Uma versão simplificada da ProfileScreen para testes
class TestProfileScreen extends StatefulWidget {
  final AuthServiceWrapper authServiceWrapper;
  final EscolasServiceWrapper escolasServiceWrapper;
  final SharedPreferencesHelperWrapper sharedPreferencesHelperWrapper;
  final UtilsWrapper utilsWrapper;

  const TestProfileScreen({
    super.key,
    required this.authServiceWrapper,
    required this.escolasServiceWrapper,
    required this.sharedPreferencesHelperWrapper,
    required this.utilsWrapper,
  });

  @override
  State<TestProfileScreen> createState() => _TestProfileScreenState();
}

class _TestProfileScreenState extends State<TestProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  EscolaModel? _selectedSchool;
  bool _isLoading = false;
  List<EscolaModel> _escolas = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadEscolas();
  }

  void _loadCurrentUser() {
    _currentUser = widget.sharedPreferencesHelperWrapper.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name ?? '';
      _phoneController.text = _currentUser!.phoneNumber ?? '';
    }
  }

  Future<void> _loadEscolas() async {
    final result = await widget.escolasServiceWrapper.getEscolas();
    result.fold((error) {
      // Lidar com erro, talvez exibir um SnackBar
    }, (schools) {
      setState(() {
        _escolas = schools;
        if (_currentUser?.idEscola != null) {
          try {
            _selectedSchool = _escolas
                .firstWhere((school) => school.id == _currentUser!.idEscola);
          } catch (e) {
            // Escola não encontrada, manter nulo
          }
        }
      });
    });
  }

  Future<void> _handleUpdateProfile() async {
    if (_currentUser == null) {
      widget.utilsWrapper.showTopSnackBar(context, "Erro: usuário não encontrado");
      return;
    }

    setState(() => _isLoading = true);

    final updatedUser = _currentUser!.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      idEscola: _selectedSchool?.id,
    );

    final result = await widget.authServiceWrapper.databaseUpdateUser(updatedUser);

    result.fold(
      (error) {
        widget.utilsWrapper.showTopSnackBar(context, "Erro ao atualizar perfil: $error");
      },
      (user) {
        widget.sharedPreferencesHelperWrapper.currentUser = user;
        setState(() => _currentUser = user);
        widget.utilsWrapper.showTopSnackBar(context, "Perfil atualizado com sucesso!");
      },
    );

    setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: const Text('Test Profile Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('MEU PERFIL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(
                _currentUser?.email ?? 'Email não disponível',
                key: const Key('emailText'), // Adicionado Key para facilitar o teste
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              DropdownButtonFormField<EscolaModel>(
                key: const Key('schoolDropdown'), // Adicionado Key para facilitar o teste
                value: _selectedSchool,
                decoration: const InputDecoration(labelText: 'Escola'),
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
              ),
              DefaultButtonWidget(
                onPressed: _isLoading ? null : _handleUpdateProfile,
                color: Colors.green,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SALVAR ALTERAÇÕES'),
              ),
              DefaultButtonWidget(
                onPressed: _handleLogout,
                color: Colors.red,
                child: const Text('SAIR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
