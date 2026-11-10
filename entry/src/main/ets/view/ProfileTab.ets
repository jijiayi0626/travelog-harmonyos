import { AppStorageV2 } from '@kit.ArkUI';
import { ProfileViewModel } from '../viewmodel/ProfileViewModel';
import { StatTile } from '../components/StatTile';
import { MenuRow } from '../components/MenuRow';
import { Avatar } from '../components/Avatar';
import { AppRefresh } from '../service/AppRefresh';
import { UserSession } from '../service/UserSession';
import { AppRouter, RouteName, EmptyParam } from '../common/Routes';

@ComponentV2
export struct ProfileTab {
  @Local vm: ProfileViewModel = new ProfileViewModel();
  @Local session: UserSession = AppStorageV2.connect(UserSession, 'UserSession', () => new UserSession())!;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  aboutToAppear(): void {
    this.vm.load();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.vm.load();
  }

  private openAccount(): void {
    const param: EmptyParam = { from: 'profileTab' };
    AppRouter.push(RouteName.ACCOUNT, param);
  }

  private openSync(): void {
    const param: EmptyParam = { from: 'profileTab' };
    AppRouter.push(RouteName.SYNC, param);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row({ space: 12 }) {
          Avatar({
            name: this.session.nickname,
            avatarUri: this.session.avatarUri,
            size: 52
          })

          Column({ space: 4 }) {
            Text(this.session.nickname !== '' ? this.session.nickname : $r('app.string.default_user_name'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text($r('app.string.account_local'))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text($r('app.string.profile_edit_profile'))
            .fontSize(12)
            .fontColor($r('app.color.primary'))
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .onClick(() => this.openAccount())

        Column({ space: 10 }) {
          Text($r('app.string.profile_data_stats'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')

          Row() {
            StatTile({ value: '' + this.vm.stats.tripCount, label: $r('app.string.profile_stat_trips') })
            StatTile({ value: '' + this.vm.stats.momentCount, label: $r('app.string.profile_stat_moments') })
            StatTile({ value: '' + this.vm.stats.footprintCount, label: $r('app.string.profile_stat_footprints') })
            StatTile({ value: '' + this.vm.stats.expenseCount, label: $r('app.string.profile_stat_expenses') })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)

        Column({ space: 10 }) {
          Text($r('app.string.profile_sync_title'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')

          MenuRow({
            icon: '☁️',
            title: $r('app.string.profile_sync_not_configured'),
            subtitle: $r('app.string.profile_sync_hint'),
            onClick: () => this.openSync()
          })

          MenuRow({
            icon: '👤',
            title: $r('app.string.account_title'),
            subtitle: $r('app.string.account_local'),
            onClick: () => this.openAccount()
          })

          MenuRow({
            icon: 'ℹ️',
            title: $r('app.string.profile_about'),
            subtitle: $r('app.string.profile_about_desc'),
            onClick: () => {}
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.page_bg'))
  }
}