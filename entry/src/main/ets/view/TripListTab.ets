import { AppStorageV2 } from '@kit.ArkUI';
import { TripListViewModel } from '../viewmodel/TripListViewModel';
import { TripCard } from '../components/TripCard';
import { EmptyState } from '../components/EmptyState';
import { AppRefresh } from '../service/AppRefresh';
import { AppRouter, RouteName, TripDetailParam, TripEditParam } from '../common/Routes';
import { Trip } from '../model/Entities';

@ComponentV2
export struct TripListTab {
  @Local vm: TripListViewModel = new TripListViewModel();
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  aboutToAppear(): void {
    this.vm.load();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.vm.load();
  }

  private openDetail(trip: Trip): void {
    const param: TripDetailParam = { tripId: trip.id };
    AppRouter.push(RouteName.TRIP_DETAIL, param);
  }

  private openCreate(): void {
    const param: TripEditParam = { tripId: '' };
    AppRouter.push(RouteName.TRIP_EDIT, param);
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text($r('app.string.trip_list_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text($r('app.string.subtitle_trips'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button({ type: ButtonType.Normal }) {
          Row({ space: 4 }) {
            Text('＋')
              .fontSize(16)
              .fontColor($r('app.color.white'))
            Text($r('app.string.action_create'))
              .fontSize(13)
              .fontColor($r('app.color.white'))
          }
        }
        .backgroundColor($r('app.color.primary'))
        .borderRadius(18)
        .height(36)
        .padding({ left: 14, right: 14 })
        .onClick(() => this.openCreate())
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
      } else if (this.vm.trips.length === 0) {
        EmptyState({
          icon: '🧭',
          title: $r('app.string.empty_trips'),
          hint: $r('app.string.empty_trips_hint')
        })
      } else {
        List({ space: 12 }) {
          ForEach(this.vm.trips, (trip: Trip) => {
            ListItem() {
              TripCard({
                trip: trip,
                onClick: () => this.openDetail(trip)
              })
            }
          }, (trip: Trip) => trip.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}