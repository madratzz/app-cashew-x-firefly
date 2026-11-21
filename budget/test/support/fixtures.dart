import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';

final fixtureTime = DateTime.utc(2024, 1, 1);

JsonObject fireflyResource(String type, String id, JsonObject attributes) => {
      'type': type,
      'id': id,
      'attributes': attributes,
      'links': <String, Object?>{'self': '/api/v1/$type/$id'},
    };

FireflyIdMapping fixtureMapping({
  FireflyEntityType type = FireflyEntityType.category,
  String localPk = 'local',
  String remoteId = '1',
  String subId = '',
  int role = 0,
  DateTime? localVersionAt,
  DateTime? remoteUpdatedAt,
  String? syncedHash,
  FireflySyncState state = FireflySyncState.synced,
}) =>
    FireflyIdMapping(
      entityType: type,
      localPk: localPk,
      remoteId: remoteId,
      remoteSubId: subId,
      remoteRole: role,
      localVersionAt: localVersionAt,
      remoteUpdatedAt: remoteUpdatedAt,
      syncedHash: syncedHash,
      state: state,
      attempts: 0,
    );
