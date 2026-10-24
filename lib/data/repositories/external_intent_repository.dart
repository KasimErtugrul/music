import 'package:resonance/data/datasources/external_intent_datasource.dart';

abstract class ExternalIntentRepository {
  Future<String?> getInitialUri();
  void listenForNewIntents(void Function(String uri) callback);
}

class ExternalIntentRepositoryImpl implements ExternalIntentRepository {
  final ExternalIntentDatasource _datasource;
  ExternalIntentRepositoryImpl(this._datasource);

  @override
  Future<String?> getInitialUri() => _datasource.getInitialIntent();

  @override
  void listenForNewIntents(void Function(String uri) callback) {
    _datasource.listenToIntents(callback);
  }
}