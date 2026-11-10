import { AppStorageV2 } from '@kit.ArkUI';
import { EmptyParam, AppRouter } from '../common/Routes';
import { UserProfile } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { UserSession } from '../service/UserSession';
import { Avatar } from '../components/Avatar';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct AccountPage {
  @Param param: EmptyParam = { from: '' };
  @Local nickname: string = '';
  @Local avatarUri: string = '';
  @Local loading: boolean = true;
  @Local saving: boolean = false;
  @Local session: UserSession = AppStorageV2.connect(UserSession, 'UserSession', () => new UserSession())!;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();
  private profile: UserProfile = new UserProfile();

  async aboutToAppear(): Promise<void> {
    this.profile = await this.repository.getProfile();
    this.nickname = this.profile.nickname;
    this.avatarUri = this.profile.avatarUri;
    this.loading = false;
  }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    if (this.nickname.trim() === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    this.saving = true;
    this.profile.nickname = this.nickname.trim();
    this.profile.avatarUri = this.avatarUri;
    await this.repository.saveProfile(this.profile);
    this.session.userId = this.profile.id;
    this.session.nickname = this.profile.nickname;
    this.session.avatarUri = this.profile.avatarUri;
    this.refresh.bump();
    this.saving = false;
    showToast(this.getUIContext(), $r('app.string.toast_saved'));
    AppRouter.pop();
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 12 }) {
          Avatar({
            name: this.nickname,
            avatarUri: this.avatarUri,
            size: 72
          })
          Text($r('app.string.account_local'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(20)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)

        Column({ space: 10 }) {
          Text($r('app.string.account_nickname_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          TextInput({ placeholder: $r('app.string.account_nickname_placeholder'), text: this.nickname })
            .height(44)
            .fontSize(15)
            .backgroundColor($r('app.color.page_bg'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.nickname = value;
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Text($r('app.string.account_multi_tip'))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)

        Button($r('app.string.action_save'))
          .width('100%')
          .height(46)
          .fontSize(15)
          .borderRadius(23)
          .backgroundColor($r('app.color.primary'))
          .enabled(!this.saving)
          .onClick(() => this.save())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.account_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}