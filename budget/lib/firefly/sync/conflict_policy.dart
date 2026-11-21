enum LocalSyncVersion { missing, clean, dirty, pendingDelete }

enum RemoteSyncVersion { missing, unchanged, changed, deleted }

enum ConflictDecision {
  none,
  createRemote,
  insertLocal,
  applyRemote,
  applyRemoteWithConflict,
  markSynced,
  pushLocal,
  deleteRemote,
  deleteLocal,
  deleteLocalWithConflict,
}

ConflictDecision resolveConflict({
  required LocalSyncVersion local,
  required RemoteSyncVersion remote,
  bool sameHash = false,
}) {
  if (remote == RemoteSyncVersion.deleted) {
    return local == LocalSyncVersion.dirty
        ? ConflictDecision.deleteLocalWithConflict
        : ConflictDecision.deleteLocal;
  }
  if (remote == RemoteSyncVersion.missing) {
    return local == LocalSyncVersion.clean || local == LocalSyncVersion.dirty
        ? ConflictDecision.createRemote
        : ConflictDecision.none;
  }
  if (local == LocalSyncVersion.missing) return ConflictDecision.insertLocal;
  if (local == LocalSyncVersion.pendingDelete) {
    return remote == RemoteSyncVersion.changed
        ? ConflictDecision.applyRemoteWithConflict
        : ConflictDecision.deleteRemote;
  }
  if (remote == RemoteSyncVersion.unchanged) {
    return local == LocalSyncVersion.dirty
        ? ConflictDecision.pushLocal
        : ConflictDecision.none;
  }
  if (local == LocalSyncVersion.dirty && sameHash) {
    return ConflictDecision.markSynced;
  }
  return local == LocalSyncVersion.dirty
      ? ConflictDecision.applyRemoteWithConflict
      : ConflictDecision.applyRemote;
}
