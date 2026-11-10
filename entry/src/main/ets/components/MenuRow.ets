@ComponentV2
export struct MenuRow {
  @Param icon: string = '⚙️';
  @Param title: Resource = $r('app.string.profile_about');
  @Param subtitle: ResourceStr = '';
  @Event onClick: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(18)
        .width(38)
        .height(38)
        .borderRadius(12)
        .backgroundColor($r('app.color.page_bg'))
        .textAlign(TextAlign.Center)

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
        Text(this.subtitle)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => this.onClick())
  }
}