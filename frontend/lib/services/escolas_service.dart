import 'package:corigge/environment.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:dartz/dartz.dart';

class EscolasService {
  static Future<Either<String, List<EscolaModel>>> getEscolas() async {
    try {
      final response = await Environment.dio.get('/escolas/list');
      return Right(List<EscolaModel>.from(
          response.data.map((e) => EscolaModel.fromJson(e)).toList()));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
