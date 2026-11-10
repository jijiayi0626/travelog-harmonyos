import { AppStorageV2 } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { MembersParam } from '../common/Routes';
import { Trip, TripMember } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { Avatar } from '../components/Avatar';
import { EmptyState } from '../components/EmptyState';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct MembersPage {
  @Param param: MembersParam = { tripId: '' };
  @Local members: TripMember[] = [];
  @Local newName: string = '';
  @Local inviteCode: string = '';
  @Local loading: boolean = true;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();

  async aboutToAppear(): Promise<void> {
    await this.load();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.members = await this.repository.listMembers(this.param.tripId);
    const trip: Trip | undefined = await this.repository.getTrip(this.param.tripId);
    if (trip !== undefined) {
      this.inviteCode = trip.inviteCode;
    }
    this.loading = false;
  }

  private async add(): Promise<void> {
    const name: string = this.newName.trim();
    if (name === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    await this.repository.addMember(this.param.tripId, name);
    this.newName = '';
    this.refresh.bump();
  }

  private async copyInvite(): Promise<void> {
    if (this.inviteCode === '') {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN, this.inviteCode);
      await pasteboard.getSystemPasteboard().setData(data);
      showToast(this.getUIContext(), $r('app.string.toast_copied'));
    } catch (err) {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        if (this.inviteCode !== '') {
          Row() {
            Text($r('app.string.members_invite_format', this.inviteCode))
              .fontSize(13)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text($r('app.string.members_copy'))
              .fontSize(12)
              .fontColor($r('app.color.primary'))
              .onClick(() => this.copyInvite())
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)
          .margin({ top: 10 })
        }

        Row({ space: 8 }) {
          TextInput({ placeholder: $r('app.string.members_name_placeholder'), text: this.newName })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)
            .onChange((value: string) => {
              this.newName = value;
            })
          Button($r('app.string.members_add'))
            .height(40)
            .fontSize(13)
            .borderRadius(20)
            .backgroundColor($r('app.color.primary'))
            .onClick(() => this.add())
        }
        .width('100%')

        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color($r('app.color.primary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.members.length === 0) {
          EmptyState({
            icon: '🧑‍🤝‍🧑',
            title: $r('app.string.empty_members'),
            hint: $r('app.string.profile_members_hint')
          })
        } else {
          List({ space: 8 }) {
            ForEach(this.members, (member: TripMember) => {
              ListItem() {
                Row({ space: 12 }) {
                  Avatar({ name: member.name, size: 42 })
                  Column({ space: 2 }) {
                    Text(member.name)
                      .fontSize(15)
                      .fontColor($r('app.color.text_primary'))
                    Text(member.role === 'owner' ? $r('app.string.members_role_owner') : $r('app.string.members_role_member'))
                      .fontSize(11)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  if (member.role !== 'owner') {
                    Text($r('app.string.action_delete'))
                      .fontSize(12)
                      .fontColor($r('app.color.text_tertiary'))
                      .onClick(() => this.removeMember(member))
                  }
                }
                .width('100%')
                .padding(12)
                .backgroundColor($r('app.color.card_bg'))
                .borderRadius(14)
              }
            }, (member: TripMember) => member.id)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.members_title'))
    .backgroundColor($r('app.color.page_bg'))
  }

  private async removeMember(member: TripMember): Promise<void> {
    await this.repository.removeMember(member.id);
    this.refresh.bump();
  }
}