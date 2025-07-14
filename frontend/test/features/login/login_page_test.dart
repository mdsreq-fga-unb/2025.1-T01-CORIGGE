import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/services/auth_service_wrapper.dart';
import 'package:corigge/utils/utils_wrapper.dart'; // Importar UtilsWrapper
import 'package:corigge/features/login/presentation/page/login_page.dart'; // Importar a LoginPage original
import 'package:corigge/features/login/test_login_page.dart'; // Importar a TestLoginPage
import 'package:dartz/dartz.dart';
import 'package:corigge/config/size_config.dart';
import 'package:flutter/services.dart';

import 'login_page_test.mocks.dart';

// Mock do GoRouter para testes
class MockGoRouter extends Mock implements GoRouter {}

@GenerateMocks([AuthServiceWrapper, UtilsWrapper]) // Gerar mock para o wrapper
void main() {
  late MockAuthServiceWrapper mockAuthServiceWrapper;
  late MockGoRouter mockGoRouter;
  late MockUtilsWrapper mockUtilsWrapper; // Usar o mock do wrapper

  setUp(() {
    mockAuthServiceWrapper = MockAuthServiceWrapper();
    mockGoRouter = MockGoRouter();
    mockUtilsWrapper = MockUtilsWrapper();

    // Inicializar SizeConfig com um tamanho de tela fixo para testes
    TestWidgetsFlutterBinding.ensureInitialized();
    SizeConfig.screenWidth = 1920.0;
    SizeConfig.screenHeight = 1080.0;
    SizeConfig.orientation = Orientation.portrait;
    SizeConfig.normalSpacing = getProportionateScreenHeight(10);
    SizeConfig.largeSpacing = getProportionateScreenHeight(20);
    SizeConfig.figmaScreenHeight = SizeConfig.screenHeight;
    SizeConfig.figmaScreenWidth = SizeConfig.screenWidth;

    // Mock do asset SVG usando rootBundle.load
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        if (message == 'assets/images/logo_corigge.svg') {
          return ByteData(0); // Retorna um ByteData vazio para o SVG
        }
        return null; // Para outros assets, não mockar
      },
    );

    // Mockar UtilsWrapper.showTopSnackBar
    when(mockUtilsWrapper.showTopSnackBar(any, any, color: anyNamed('color'))).thenReturn(null);
  });

  testWidgets('TestLoginPage displays Sign in with Google button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
        child: MaterialApp(
          home: TestLoginPage(authServiceWrapper: mockAuthServiceWrapper, utilsWrapper: mockUtilsWrapper), // Usar TestLoginPage e injetar mockUtilsWrapper
        ),
      ),
    );

    expect(find.text('SIGN IN WITH GOOGLE'), findsOneWidget);
  });

  testWidgets('TestLoginPage navigates to /home on successful login', (WidgetTester tester) async {
    when(mockAuthServiceWrapper.signInWithGoogle()).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: TestLoginPage(authServiceWrapper: mockAuthServiceWrapper, utilsWrapper: mockUtilsWrapper), // Usar TestLoginPage e injetar mockUtilsWrapper
          ),
        ),
      ),
    );

    await tester.tap(find.text('SIGN IN WITH GOOGLE'));
    await tester.pumpAndSettle();

    verify(mockGoRouter.go('/home')).called(1);
  });

  testWidgets('TestLoginPage navigates to /registro on "User not found" error', (WidgetTester tester) async {
    when(mockAuthServiceWrapper.signInWithGoogle()).thenAnswer((_) async => const Left('User not found'));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: TestLoginPage(authServiceWrapper: mockAuthServiceWrapper, utilsWrapper: mockUtilsWrapper), // Usar TestLoginPage e injetar mockUtilsWrapper
          ),
        ),
      ),
    );

    await tester.tap(find.text('SIGN IN WITH GOOGLE'));
    await tester.pumpAndSettle();

    verify(mockGoRouter.go('/registro')).called(1);
  });

  testWidgets('TestLoginPage displays SnackBar on other login errors', (WidgetTester tester) async {
    when(mockAuthServiceWrapper.signInWithGoogle()).thenAnswer((_) async => const Left('Some other error'));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(SizeConfig.screenWidth, SizeConfig.screenHeight)),
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: TestLoginPage(authServiceWrapper: mockAuthServiceWrapper, utilsWrapper: mockUtilsWrapper), // Usar TestLoginPage e injetar mockUtilsWrapper
          ),
        ),
      ),
    );

    await tester.tap(find.text('SIGN IN WITH GOOGLE'));
    await tester.pump();

    verify(mockUtilsWrapper.showTopSnackBar(any, 'Erro ao fazer login: Some other error', color: anyNamed('color'))).called(1);
  });
}
