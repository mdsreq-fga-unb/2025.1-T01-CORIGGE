import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../cache/shared_preferences_helper.dart';
import '../../../../environment.dart';
import '../../../../services/local_process_server_service.dart';
import '../../../login/data/user_model.dart';

var log = Logger("AuthService");

class AuthService {
  static const List<String> _scopes = ['openid', 'email', 'profile'];
  static String get _clientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  }

  static String get _clientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  static const String _redirectUri = 'http://localhost:3500';

  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url
        .encode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static Future<void> logout() async {
    await SharedPreferencesHelper.clearUserData();
    await Supabase.instance.client.auth.signOut();
  }

  static Future<Either<String, UserModel>> databaseSearchUser(
      String email) async {
    try {
      final response =
          await Environment.dio.get('/users/exists', queryParameters: {
        'email': email,
      });

      if (response.statusCode == 404) {
        return Left("[$email] not found");
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to search user: ${response.statusMessage}');
      }

      final userMap = response.data;
      final user = UserModel.fromJson(userMap);

      await SharedPreferencesHelper.saveOrUpdateUserData(user);

      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left("[$email] not found");
      }
      log.severe('Error searching user in database', e);
      return Left('Error searching user: ${e.message}');
    } catch (e, stackTrace) {
      log.severe('Error searching user in database', e, stackTrace);
      return Left('Error searching user: $e');
    }
  }

  static Future<void> databaseInsertUser(UserModel user) async {
    try {
      final response = await Environment.dio.post('/users/create', data: {
        'email': user.email,
        'nome_completo': user.name,
        'phone_number': user.phoneNumber ?? '',
        'id_escola': user.idEscola,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to create user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      log.severe('Error creating user in database', e);
      throw Exception('Failed to create user: ${e.message}');
    }
  }

  static Future<Either<String, UserModel>> databaseUpdateUser(
      UserModel user) async {
    try {
      final response = await Environment.dio.put('/users/update', data: {
        'id_user': user.id,
        'nome_completo': user.name,
        'phone_number': user.phoneNumber ?? '',
        'id_escola': user.idEscola,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.statusMessage}');
      }

      final userMap = response.data;
      final updatedUser = UserModel.fromJson(userMap);

      await SharedPreferencesHelper.saveOrUpdateUserData(updatedUser);

      return Right(updatedUser);
    } on DioException catch (e) {
      log.severe('Error updating user in database', e);
      return Left('Error updating user: ${e.message}');
    } catch (e, stackTrace) {
      log.severe('Error updating user in database', e, stackTrace);
      return Left('Error updating user: $e');
    }
  }

  static Future<Map<String, dynamic>> _exchangeCodeForTokens(
      String code, String codeVerifier) async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw Exception(
          'Google OAuth credentials not found in environment variables');
    }

    final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
    final response = await http.post(
      tokenEndpoint,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'redirect_uri': _redirectUri,
      },
    );

    if (response.statusCode != 200) {
      log.severe('Token exchange failed: ${response.body}');
      throw Exception(
          'Failed to exchange code for tokens: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  static Future<Either<String, UserModel>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        throw UnimplementedError('Web platform is not supported yet');
      }

      if (_clientId.isEmpty || _clientSecret.isEmpty) {
        return const Left(
            'Google OAuth credentials not found in environment variables');
      }

      // Generate PKCE values
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateCodeVerifier();

      // Construct Google OAuth URL
      final queryParams = {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'access_type': 'offline',
        'prompt': 'consent'
      };

      final authUrl = Uri.https(
        'accounts.google.com',
        '/o/oauth2/v2/auth',
        queryParams,
      );

      // Launch browser with auth URL
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch auth URL';
      }

      // Start local server to handle callback
      final callbackUri =
          await LocalProcessServerService.startServerAndWaitForCallback();

      // Wait for and validate callback
      if (callbackUri.queryParameters['state'] != state) {
        throw 'Invalid state parameter';
      }

      final code = callbackUri.queryParameters['code'];
      if (code == null) {
        throw 'No authorization code received';
      }

      // Exchange code for tokens
      final tokens = await _exchangeCodeForTokens(code, codeVerifier);
      final idToken = tokens['id_token'];

      if (idToken == null) {
        throw 'No ID token received';
      }

      // Sign in to Supabase with the ID token
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user?.email == null) {
        return const Left('Failed to get user email');
      }

      // Check if user exists in database
      final userResult = await databaseSearchUser(response.user!.email!);

      return await userResult.fold(
        (error) async {
          // send to register page
          if (error.contains("not found")) {
            // send to register page
            return Left('User not found');
          }

          return Left('Error signing in: $error');
        },
        (user) {
          return Right(user);
        },
      );
    } catch (e, stackTrace) {
      log.severe('Error signing in with Google', e, stackTrace);
      return Left('Error signing in: $e');
    } finally {
      // Clean up server
      await LocalProcessServerService.stopServer();
    }
  }
}
