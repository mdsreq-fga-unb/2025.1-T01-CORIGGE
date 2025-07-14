import 'package:corigge/features/splash/domain/repositories/auth_service.dart';
import 'package:dartz/dartz.dart';
import 'package:corigge/features/login/data/user_model.dart';

class AuthServiceWrapper {
  Future<Either<String, UserModel?>> signInWithGoogle() {
    return AuthService.signInWithGoogle();
  }

  Future<Either<String, UserModel>> databaseUpdateUser(UserModel user) {
    return AuthService.databaseUpdateUser(user);
  }

  Future<void> logout() {
    return AuthService.logout();
  }
}