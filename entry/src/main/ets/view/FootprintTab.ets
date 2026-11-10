import { AppStorageV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { FootprintViewModel } from '../viewmodel/FootprintViewModel';
import { FootprintCard } from '../components/FootprintCard';
import { EmptyState } from '../components/EmptyState';
import { AppRefresh } from '../service/AppRefresh';
import { SystemMapLauncher } from '../service/MapProvider';
import { AppRouter, RouteName, EmptyParam } from '../common/Routes';
import { Footprint } from '../model/Entities';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct FootprintTab {
  @Local vm: FootprintViewModel = new FootprintViewModel();
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  aboutToAppear(): void {
    this.vm.load();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.vm.load();
  }

  private openCheckin(): void {
    const param: EmptyParam = { from: 'footprintTab' };
    AppRouter.push(RouteName.FOOTPRINT_EDIT, param);
  }

  private async openMap(footprint: Footprint): Promise<void> {
    if (footprint.latitude === 0 && footprint.longitude === 0) {
      return;
    }
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await SystemMapLauncher.open(context, footprint.latitude, footprint.longitude, footprint.placeName);
    } catch (err) {
      showToast(this.getUIContext(), $r('app.string.footprint_locate_failed'));
    }
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text($r('app.string.footprint_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Row({ space: 4 }) {
            Text($r('app.string.footprint_visited_format', this.vm.footprints.length))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text('·')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text($r('app.string.footprint_city_format', this.vm.cityCount))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button({ type: ButtonType.Normal }) {
          Row({ space: 4 }) {
            Text('📍')
              .fontSize(14)
            Text($r('app.string.footprint_checkin'))
              .fontSize(13)
              .fontColor($r('app.color.white'))
          }
        }
        .backgroundColor($r('app.color.primary'))
        .borderRadius(18)
        .height(36)
        .padding({ left: 14, right: 14 })
        .onClick(() => this.openCheckin())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.vm.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.primary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.footprints.length === 0) {
        EmptyState({
          icon: '📍',
          title: $r('app.string.empty_footprints'),
          hint: $r('app.string.footprint_map_tip')
        })
      } else {
        List({ space: 10 }) {
          ForEach(this.vm.footprints, (footprint: Footprint) => {
            ListItem() {
              FootprintCard({
                footprint: footprint,
                onClick: () => this.openMap(footprint)
              })
            }
          }, (footprint: Footprint) => footprint.id)

          ListItem() {
            Text($r('app.string.footprint_map_tip'))
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 8 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}