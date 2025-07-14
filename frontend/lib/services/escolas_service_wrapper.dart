import 'package:dartz/dartz.dart';
import 'package:corigge/models/escola_model.dart';
import 'package:corigge/services/escolas_service.dart';

class EscolasServiceWrapper {
  Future<Either<String, List<EscolaModel>>> getEscolas() {
    return EscolasService.getEscolas();
  }
}
