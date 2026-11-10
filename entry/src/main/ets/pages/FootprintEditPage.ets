import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { EmptyParam, AppRouter } from '../common/Routes';
import { Footprint } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { LocationService } from '../service/LocationService';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct FootprintEditPage {
  @Param param: EmptyParam = { from: '' };
  @Local placeName: string = '';
  @Local city: string = '';
  @Local note: string = '';
  @Local latitude: number = 0;
  @Local longitude: number = 0;
  @Local locating: boolean = false;
  @Local saving: boolean = false;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();

  private async locate(): Promise<void> {
    if (this.locating) {
      return;
    }
    this.locating = true;
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const granted: boolean = await LocationService.requestPermission(context);
    if (!granted) {
      showToast(this.getUIContext(), $r('app.string.footprint_permission_denied'));
      this.locating = false;
      return;
    }
    const coordinate = await LocationService.getCurrent();
    if (coordinate === undefined) {
      showToast(this.getUIContext(), $r('app.string.footprint_locate_failed'));
    } else {
      this.latitude = coordinate.latitude;
      this.longitude = coordinate.longitude;
    }
    this.locating = false;
  }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    if (this.placeName.trim() === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    this.saving = true;
    const footprint: Footprint = new Footprint();
    footprint.placeName = this.placeName.trim();
    footprint.city = this.city.trim();
    footprint.note = this.note.trim();
    footprint.latitude = this.latitude;
    footprint.longitude = this.longitude;
    footprint.visitedAt = Date.now();
    footprint.createdAt = Date.now();
    await this.repository.saveFootprint(footprint);
    this.refresh.bump();
    this.saving = false;
    showToast(this.getUIContext(), $r('app.string.toast_saved'));
    AppRouter.pop();
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 10 }) {
          Text($r('app.string.footprint_place_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          TextInput({ placeholder: $r('app.string.footprint_place_placeholder'), text: this.placeName })
            .height(44)
            .fontSize(15)
            .backgroundColor($r('app.color.page_bg'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.placeName = value;
            })

          Text($r('app.string.footprint_city_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          TextInput({ placeholder: $r('app.string.footprint_city_placeholder'), text: this.city })
            .height(44)
            .fontSize(14)
            .backgroundColor($r('app.color.page_bg'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.city = value;
            })

          Text($r('app.string.footprint_note_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          TextInput({ placeholder: $r('app.string.footprint_note_label'), text: this.note })
            .height(44)
            .fontSize(14)
            .backgroundColor($r('app.color.page_bg'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.note = value;
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Row({ space: 10 }) {
          Column({ space: 2 }) {
            Text(this.locating ? $r('app.string.footprint_locating') : $r('app.string.footprint_locate'))
              .fontSize(13)
              .fontColor($r('app.color.primary'))
            if (this.latitude !== 0 || this.longitude !== 0) {
              Text(this.latitude.toFixed(4) + ', ' + this.longitude.toFixed(4))
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('📍')
            .fontSize(20)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .onClick(() => this.locate())

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
      .padding({ left: 16, right: 16, top: 12 })
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.footprint_checkin_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}