import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/services/auth_service_wrapper.dart';
import 'package:corigge/services/escolas_service_wrapper.dart';
import 'package:corigge/cache/shared_preferences_helper_wrapper.dart';
import 'package:corigge/utils/utils_wrapper.dart';
import 'package:corigge/features/profile/test_profile_screen.dart';
import 'package:corigge/features/login/data/user_model.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:dartz/dartz.dart';
import 'package:corigge/config/size_config.dart';
import 'package:corigge/config/theme.dart'; // Importar theme.dart para kError

import 'profile_screen_test.mocks.dart';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}

@GenerateMocks([
  AuthServiceWrapper,
  EscolasServiceWrapper,
  SharedPreferencesHelperWrapper,
  UtilsWrapper,
])
void main() {
  late MockAuthServiceWrapper mockAuthServiceWrapper;
  late MockEscolasServiceWrapper mockEscolasServiceWrapper;
  late MockSharedPreferencesHelperWrapper mockSharedPreferencesHelperWrapper;
  late MockUtilsWrapper mockUtilsWrapper;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockAuthServiceWrapper = MockAuthServiceWrapper();
    mockEscolasServiceWrapper = MockEscolasServiceWrapper();
    mockSharedPreferencesHelperWrapper = MockSharedPreferencesHelperWrapper();
    mockUtilsWrapper = MockUtilsWrapper();
    mockGoRouter = MockGoRouter();

    // Inicializar SizeConfig com um tamanho de tela fixo para testes
    TestWidgetsFlutterBinding.ensureInitialized();
    SizeConfig.screenWidth = 1920.0;
    SizeConfig.screenHeight = 1080.0;
    SizeConfig.orientation = Orientation.portrait;
    SizeConfig.normalSpacing = getProportionateScreenHeight(10);
    SizeConfig.largeSpacing = getProportionateScreenHeight(20);
    SizeConfig.figmaScreenHeight = SizeConfig.screenHeight;
    SizeConfig.figmaScreenWidth = SizeConfig.screenWidth;

    // Mockar UtilsWrapper.showTopSnackBar
    when(mockUtilsWrapper.showTopSnackBar(any, any, color: anyNamed('color'))).thenReturn(null);
  });

  group('TestProfileScreen', () {
    testWidgets('displays user profile fields and buttons', (WidgetTester tester) async {
      // Mock de dados iniciais
      final currentUser = UserModel(id: 1, email: 'test@example.com', name: 'Test User', phoneNumber: '1234567890');
      final escolas = [EscolaModel(id: 1, nome: 'Escola A'), EscolaModel(id: 2, nome: 'Escola B')];

      when(mockSharedPreferencesHelperWrapper.currentUser).thenReturn(currentUser);
      when(mockEscolasServiceWrapper.getEscolas()).thenAnswer((_) async => Right(escolas));

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
          child: MaterialApp(
            home: TestProfileScreen(
              authServiceWrapper: mockAuthServiceWrapper,
              escolasServiceWrapper: mockEscolasServiceWrapper,
              sharedPreferencesHelperWrapper: mockSharedPreferencesHelperWrapper,
              utilsWrapper: mockUtilsWrapper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Aguarda o FutureBuilder resolver

      expect(find.text('MEU PERFIL'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Telefone'), findsOneWidget);
      expect(find.text('Escola'), findsOneWidget);
      expect(find.text('SALVAR ALTERAÇÕES'), findsOneWidget);
      expect(find.text('SAIR'), findsOneWidget);

      // Verificar se os dados do usuário são exibidos
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });

    // Teste para atualização de perfil
    testWidgets('updates user profile successfully', (WidgetTester tester) async {
      final currentUser = UserModel(id: 1, email: 'test@example.com', name: 'Old Name', phoneNumber: '1111111111');
      final updatedUser = UserModel(id: 1, email: 'test@example.com', name: 'New Name', phoneNumber: '2222222222', idEscola: 1);
      final escolas = [EscolaModel(id: 1, nome: 'Escola A'), EscolaModel(id: 2, nome: 'Escola B')];

      when(mockSharedPreferencesHelperWrapper.currentUser).thenReturn(currentUser);
      when(mockEscolasServiceWrapper.getEscolas()).thenAnswer((_) async => Right(escolas));
      when(mockAuthServiceWrapper.databaseUpdateUser(any)).thenAnswer((_) async => Right(updatedUser));
      when(mockSharedPreferencesHelperWrapper.saveOrUpdateUserData(any)).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
          child: MaterialApp(
            home: TestProfileScreen(
              authServiceWrapper: mockAuthServiceWrapper,
              escolasServiceWrapper: mockEscolasServiceWrapper,
              sharedPreferencesHelperWrapper: mockSharedPreferencesHelperWrapper,
              utilsWrapper: mockUtilsWrapper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Preencher campos
      await tester.enterText(find.widgetWithText(TextFormField, 'Nome completo'), 'New Name');
      await tester.enterText(find.widgetWithText(TextFormField, 'Telefone'), '2222222222');

      // Selecionar escola (simular toque no DropdownButtonFormField e depois no item)
      await tester.tap(find.byKey(const Key('schoolDropdown'))); // Usar a Key
      await tester.pumpAndSettle(); // Aguarda o menu abrir
      await tester.tap(find.text('Escola A').last); // Tocar no item da escola
      await tester.pumpAndSettle(); // Aguarda o menu fechar e o estado atualizar

      await tester.tap(find.text('SALVAR ALTERAÇÕES'));
      await tester.pumpAndSettle();

      verify(mockAuthServiceWrapper.databaseUpdateUser(argThat(isA<UserModel>()
          .having((user) => user.name, 'name', 'New Name')
          .having((user) => user.phoneNumber, 'phoneNumber', '2222222222')
          .having((user) => user.idEscola, 'idEscola', 1)))).called(1);
      verify(mockSharedPreferencesHelperWrapper.currentUser = updatedUser).called(1);
      verify(mockUtilsWrapper.showTopSnackBar(any, 'Perfil atualizado com sucesso!')).called(1);
    });

    // Teste para logout
    testWidgets('logs out user and navigates to login screen', (WidgetTester tester) async {
      final currentUser = UserModel(id: 1, email: 'test@example.com', name: 'Test User', phoneNumber: '1234567890');
      final escolas = [EscolaModel(id: 1, nome: 'Escola A'), EscolaModel(id: 2, nome: 'Escola B')];

      when(mockSharedPreferencesHelperWrapper.currentUser).thenReturn(currentUser);
      when(mockEscolasServiceWrapper.getEscolas()).thenAnswer((_) async => Right(escolas));
      when(mockAuthServiceWrapper.logout()).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
          child: MaterialApp(
            home: InheritedGoRouter(
              goRouter: mockGoRouter,
              child: TestProfileScreen(
                authServiceWrapper: mockAuthServiceWrapper,
                escolasServiceWrapper: mockEscolasServiceWrapper,
                sharedPreferencesHelperWrapper: mockSharedPreferencesHelperWrapper,
                utilsWrapper: mockUtilsWrapper,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('SAIR'));
      await tester.pumpAndSettle();

      verify(mockAuthServiceWrapper.logout()).called(1);
      verify(mockGoRouter.go('/login')).called(1);
    });
  });
}