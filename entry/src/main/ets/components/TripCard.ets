import { Trip, TripStatus } from '../model/Entities';
import { formatDate, tripDayCount, tripStatusOf } from '../utils/DateUtil';
import { tripStatusColor, tripStatusLabel } from '../utils/CategoryUtil';

@ComponentV2
export struct TripCard {
  @Param trip: Trip = new Trip();
  @Event onClick: () => void = () => {};

  private status(): TripStatus {
    return tripStatusOf(this.trip.startDate, this.trip.endDate);
  }

  private dateRange(): string {
    if (this.trip.startDate <= 0 || this.trip.endDate <= 0) {
      return '';
    }
    return formatDate(this.trip.startDate) + ' - ' + formatDate(this.trip.endDate);
  }

  private dayText(): string {
    const days: number = tripDayCount(this.trip.startDate, this.trip.endDate);
    return days > 0 ? '· ' + days + ' 天' : '';
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text(tripStatusLabel(this.status()))
          .fontSize(10)
          .fontColor($r('app.color.white'))
          .backgroundColor(tripStatusColor(this.status()))
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        Blank()
        Text(this.trip.momentCount > 0 ? '📖 ' + this.trip.momentCount : '')
          .fontSize(12)
          .fontColor('#E5E7EB')
      }
      .width('100%')

      Blank()

      Text(this.trip.title !== '' ? this.trip.title : $r('app.string.default_trip_title'))
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.white'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 6 }) {
        Text(this.trip.destination)
          .fontSize(13)
          .fontColor('#E5E7EB')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(this.dateRange() + ' ' + this.dayText())
          .fontSize(11)
          .fontColor('#D1D5DB')
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .width('100%')
    .height(150)
    .padding(16)
    .borderRadius(20)
    .linearGradient({
      angle: 135,
      colors: [[tripStatusColor(this.status()), 0.0], ['#0F172A', 1.0]]
    })
    .shadow({ radius: 12, color: '#22000000', offsetY: 4 })
    .onClick(() => this.onClick())
  }
}