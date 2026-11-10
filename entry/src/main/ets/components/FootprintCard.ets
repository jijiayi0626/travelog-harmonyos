import { Footprint } from '../model/Entities';
import { formatDateCn } from '../utils/DateUtil';

@ComponentV2
export struct FootprintCard {
  @Param footprint: Footprint = new Footprint();
  @Event onClick: () => void = () => {};

  private hasCoordinate(): boolean {
    return this.footprint.latitude !== 0 || this.footprint.longitude !== 0;
  }

  build() {
    Row({ space: 12 }) {
      Text('📍')
        .fontSize(20)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor($r('app.color.primary_light'))
        .textAlign(TextAlign.Center)

      Column({ space: 4 }) {
        Text(this.footprint.placeName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          if (this.footprint.city !== '') {
            Text(this.footprint.city)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          Text(formatDateCn(this.footprint.visitedAt))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
        }
        if (this.footprint.note !== '') {
          Text(this.footprint.note)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.hasCoordinate()) {
        Text(this.footprint.latitude.toFixed(2) + ', ' + this.footprint.longitude.toFixed(2))
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
          .textAlign(TextAlign.End)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => this.onClick())
  }
}