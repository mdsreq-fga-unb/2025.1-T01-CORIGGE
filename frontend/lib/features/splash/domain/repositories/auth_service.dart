import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../cache/shared_preferences_helper.dart';
import '../../../login/data/user_model.dart';

var log = Logger("AuthService");

class AuthService {
  static const String _redirectUrl = 'com.crianex.lava-ja:/oauth2redirect';
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';
  static const String _clientIdIOS =
      '71176615929-uo5puu146fq3gpkljaqgmso7hpmdagtl.apps.googleusercontent.com';
  static const String _clientIdAndroid =
      '71176615929-3ufv7mm1kevj349k9jmp4ooms43qd822.apps.googleusercontent.com';
  static const List<String> _scopes = ['openid', 'email', 'profile'];

  static Future<void> logout() async {
    await SharedPreferencesHelper.clearUserData();
    await Supabase.instance.client.auth.signOut();
  }

  static Future<Either<String, UserModel>> databaseSearchUser(
      String email) async {
    try {
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('email', email)
          .limit(1);

      if (userResponse.isEmpty) {
        return Left("[$email] not found");
      }

      final userMap = userResponse[0];
      final user = UserModel.fromJson(userMap);

      await SharedPreferencesHelper.saveOrUpdateUserData(user);

      return Right(user);
    } catch (e, stackTrace) {
      log.severe('Error searching user in database', e, stackTrace);
      return Left('Error searching user: $e');
    }
  }

  static Future<Either<String, UserModel>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        throw UnimplementedError('Web platform is not supported yet');
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId:
              '693202468940-aig035i86s2tf6h7ld90511jvnquleiu.apps.googleusercontent.com',
          scopes: _scopes,
        );

        final credentials = await googleSignIn.signIn();

        if (credentials == null) {
          return const Left('User cancelled sign in');
        }

        final authentication = await credentials.authentication;

        // Here you would typically exchange the Google token for a Supabase session
        // For now, we'll just create a basic user model
        return Right(UserModel(
          name: credentials.displayName ?? '',
          email: credentials.email,
        ));
      }
    } catch (e, stackTrace) {
      log.severe('Error signing in with Google', e, stackTrace);
      return Left('Error signing in: $e');
    }
  }
}
