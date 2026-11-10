import { Moment, MomentMedia } from '../model/Entities';
import { formatTime } from '../utils/DateUtil';

@ComponentV2
export struct MomentItem {
  @Param moment: Moment = new Moment();

  build() {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Text('🕘')
          .fontSize(12)
        Text(formatTime(this.moment.createdAt))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
        if (this.moment.locationName !== '') {
          Text('📍 ' + this.moment.locationName)
            .fontSize(12)
            .fontColor($r('app.color.primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .width('100%')

      if (this.moment.content !== '') {
        Text(this.moment.content)
          .fontSize(15)
          .lineHeight(23)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
      }

      if (this.moment.media.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.moment.media, (media: MomentMedia) => {
            Image(media.uri)
              .width(92)
              .height(92)
              .borderRadius(10)
              .objectFit(ImageFit.Cover)
              .backgroundColor($r('app.color.page_bg'))
          }, (media: MomentMedia) => media.id)
        }
        .width('100%')
        .margin({ top: 2 })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
  }
}