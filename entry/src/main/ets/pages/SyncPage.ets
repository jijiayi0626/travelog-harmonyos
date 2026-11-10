import { EmptyParam } from '../common/Routes';
import { AppStats } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { ISyncService, SyncProvider, SyncResult } from '../service/SyncService';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct SyncPage {
  @Param param: EmptyParam = { from: '' };
  @Local stats: AppStats = new AppStats();
  @Local syncing: boolean = false;
  @Local lastSync: number = 0;
  @Local loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();
  private sync: ISyncService = SyncProvider.get();

  async aboutToAppear(): Promise<void> {
    this.stats = await this.repository.stats();
    this.loading = false;
  }

  private async syncNow(): Promise<void> {
    if (this.syncing) {
      return;
    }
    this.syncing = true;
    const result: SyncResult = await this.sync.syncNow();
    this.syncing = false;
    if (result.localOnly) {
      showToast(this.getUIContext(), $r('app.string.toast_sync_local'));
    } else if (result.success) {
      this.lastSync = result.syncedAt;
      showToast(this.getUIContext(), $r('app.string.toast_saved'));
    }
  }

  @Builder
  InfoLine(label: Resource, value: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .height(38)
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text('☁️')
              .fontSize(26)
            Column({ space: 2 }) {
              Text($r('app.string.sync_not_configured'))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text($r('app.string.sync_local_only'))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Column() {
          this.InfoLine($r('app.string.sync_status'), $r('app.string.sync_local_only'))
          Divider().strokeWidth(0.5).color($r('app.color.divider'))
          this.InfoLine($r('app.string.sync_pending'), $r('app.string.sync_pending_format', this.stats.pendingSyncCount))
          Divider().strokeWidth(0.5).color($r('app.color.divider'))
          this.InfoLine($r('app.string.sync_last_time'), $r('app.string.sync_never'))
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)

        Button($r('app.string.sync_now'))
          .width('100%')
          .height(46)
          .fontSize(15)
          .borderRadius(23)
          .backgroundColor($r('app.color.primary'))
          .enabled(!this.syncing)
          .onClick(() => this.syncNow())

        Column({ space: 8 }) {
          Text($r('app.string.sync_contract_title'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text($r('app.string.sync_contract_desc'))
            .fontSize(12)
            .lineHeight(20)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Text('GET /v1/sync/pull?since=cursor\nPOST /v1/sync/push\nPOST /v1/auth/login')
            .fontSize(11)
            .lineHeight(18)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.sync_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}