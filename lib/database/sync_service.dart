class SyncService {
  static final SyncService instance = SyncService._init();

  SyncService._init();

  // What if I just request an update in the background
  // The only update is database syncing, after each database sync, images are sync'd
  // This should be debounced since imports cause lots of changes rapidly
  void queueDatabaseUpdate() {}
}
