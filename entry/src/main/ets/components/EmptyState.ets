@ComponentV2
export struct EmptyState {
  @Param icon: string = '🧭';
  @Param title: Resource = $r('app.string.empty_trips');
  @Param hint: Resource = $r('app.string.empty_trips_hint');

  build() {
    Column({ space: 8 }) {
      Text(this.icon)
        .fontSize(44)
      Text(this.title)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
      Text(this.hint)
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .padding({ top: 48, bottom: 48 })
    .alignItems(HorizontalAlign.Center)
  }
}