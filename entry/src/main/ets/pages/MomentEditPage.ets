import { AppStorageV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { MomentEditParam, AppRouter } from '../common/Routes';
import { Moment, MomentMedia, Trip } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { MediaService } from '../service/MediaService';
import { dayIndexInTrip } from '../utils/DateUtil';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct MomentEditPage {
  @Param param: MomentEditParam = { tripId: '', momentId: '' };
  @Local content: string = '';
  @Local locationName: string = '';
  @Local mediaUris: string[] = [];
  @Local loading: boolean = true;
  @Local saving: boolean = false;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();
  private moment: Moment = new Moment();
  private trip: Trip = new Trip();

  async aboutToAppear(): Promise<void> {
    const trip: Trip | undefined = await this.repository.getTrip(this.param.tripId);
    if (trip !== undefined) {
      this.trip = trip;
    }
    if (this.param.momentId !== '') {
      const moments: Moment[] = await this.repository.listMoments(this.param.tripId);
      for (const item of moments) {
        if (item.id === this.param.momentId) {
          this.moment = item;
          this.content = item.content;
          this.locationName = item.locationName;
          const uris: string[] = [];
          for (const media of item.media) {
            uris.push(media.uri);
          }
          this.mediaUris = uris;
          break;
        }
      }
    }
    if (this.moment.dayIndex === 0) {
      const day: number = dayIndexInTrip(this.trip.startDate, Date.now());
      this.moment.dayIndex = day > 0 ? day : 1;
      this.moment.createdAt = Date.now();
    }
    this.moment.tripId = this.param.tripId;
    this.loading = false;
  }

  private async addPhotos(): Promise<void> {
    const remain: number = 9 - this.mediaUris.length;
    if (remain <= 0) {
      return;
    }
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const picked: string[] = await MediaService.pickAndPersist(context, remain);
      if (picked.length === 0) {
        return;
      }
      const next: string[] = this.mediaUris.slice();
      for (const uri of picked) {
        next.push(uri);
      }
      this.mediaUris = next;
    } catch (err) {
      showToast(this.getUIContext(), $r('app.string.toast_photo_failed'));
    }
  }

  private removePhoto(index: number): void {
    const uri: string = this.mediaUris[index];
    MediaService.removeQuietly(uri);
    const next: string[] = this.mediaUris.slice();
    next.splice(index, 1);
    this.mediaUris = next;
  }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    if (this.content.trim() === '' && this.mediaUris.length === 0) {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    this.saving = true;
    this.moment.tripId = this.param.tripId;
    this.moment.content = this.content.trim();
    this.moment.locationName = this.locationName.trim();
    const media: MomentMedia[] = [];
    for (let i = 0; i < this.mediaUris.length; i++) {
      const item: MomentMedia = new MomentMedia();
      item.uri = this.mediaUris[i];
      item.sortIndex = i;
      media.push(item);
    }
    this.moment.media = media;
    await this.repository.saveMoment(this.moment);
    this.refresh.bump();
    this.saving = false;
    showToast(this.getUIContext(), $r('app.string.toast_saved'));
    AppRouter.pop();
  }

  private confirmDelete(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.dialog_delete_title'),
      message: $r('app.string.dialog_delete_msg'),
      primaryButton: {
        value: $r('app.string.action_cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: $r('app.string.action_delete'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.deleteMoment();
        }
      }
    });
  }

  private async deleteMoment(): Promise<void> {
    for (const media of this.moment.media) {
      MediaService.removeQuietly(media.uri);
    }
    await this.repository.deleteMoment(this.param.momentId);
    this.refresh.bump();
    showToast(this.getUIContext(), $r('app.string.toast_deleted'));
    AppRouter.pop();
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.primary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Text($r('app.string.moment_content_label'))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
              TextArea({ placeholder: $r('app.string.moment_content_placeholder'), text: this.content })
                .height(140)
                .fontSize(15)
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(12)
                .onChange((value: string) => {
                  this.content = value;
                })

              Text($r('app.string.moment_location_label'))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
              TextInput({ placeholder: $r('app.string.moment_location_placeholder'), text: this.locationName })
                .height(44)
                .fontSize(14)
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(12)
                .onChange((value: string) => {
                  this.locationName = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 10 }) {
              Row() {
                Text($r('app.string.moment_photo_label'))
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Blank()
                Text(this.mediaUris.length + '/9')
                  .fontSize(11)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.mediaUris, (uri: string) => {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    Image(uri)
                      .width(88)
                      .height(88)
                      .borderRadius(10)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor($r('app.color.page_bg'))
                    Text('×')
                      .fontSize(14)
                      .fontColor($r('app.color.white'))
                      .width(20)
                      .height(20)
                      .textAlign(TextAlign.Center)
                      .borderRadius(10)
                      .backgroundColor($r('app.color.mask'))
                      .onClick(() => this.removePhoto(this.mediaUris.indexOf(uri)))
                  }
                  .width(88)
                  .height(88)
                  .margin({ right: 8, bottom: 8 })
                }, (uri: string) => uri)

                if (this.mediaUris.length < 9) {
                  Column({ space: 2 }) {
                    Text('＋')
                      .fontSize(22)
                      .fontColor($r('app.color.text_tertiary'))
                    Text($r('app.string.moment_add_photo'))
                      .fontSize(10)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .width(88)
                  .height(88)
                  .borderRadius(10)
                  .backgroundColor($r('app.color.page_bg'))
                  .justifyContent(FlexAlign.Center)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => this.addPhotos())
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)

            Button($r('app.string.action_save'))
              .width('100%')
              .height(46)
              .fontSize(15)
              .borderRadius(23)
              .backgroundColor($r('app.color.primary'))
              .enabled(!this.saving)
              .onClick(() => this.save())

            if (this.param.momentId !== '') {
              Button($r('app.string.action_delete'))
                .width('100%')
                .height(44)
                .fontSize(14)
                .borderRadius(22)
                .backgroundColor($r('app.color.card_bg'))
                .fontColor($r('app.color.danger'))
                .onClick(() => this.confirmDelete())
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title(this.param.momentId === '' ? $r('app.string.moment_add') : $r('app.string.moment_edit'))
    .backgroundColor($r('app.color.page_bg'))
  }
}