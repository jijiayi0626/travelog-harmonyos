export class SyncResult {
  public success: boolean = false;
  public localOnly: boolean = true;
  public message: string = '';
  public syncedAt: number = 0;
}

/**
 * 云同步契约。详见 docs/SYNC_API_CONTRACT.md。
 * 后端接入时实现 RemoteSyncService（携带 JWT、调用 /v1/sync/push 与 /v1/sync/pull）。
 */
export interface ISyncService {
  readonly configured: boolean;

  syncNow(): Promise<SyncResult>;
}

/**
 * 本地模式实现：不访问网络，只把「无云端」这一事实如实返回给 UI。
 */
export class LocalSyncService implements ISyncService {
  configured: boolean = false;

  async syncNow(): Promise<SyncResult> {
    const result: SyncResult = new SyncResult();
    result.success = false;
    result.localOnly = true;
    result.message = 'local-only';
    result.syncedAt = 0;
    return result;
  }
}

export class SyncProvider {
  private static service: ISyncService = new LocalSyncService();

  static get(): ISyncService {
    return SyncProvider.service;
  }

  static use(service: ISyncService): void {
    SyncProvider.service = service;
  }
}