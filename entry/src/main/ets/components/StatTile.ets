@ComponentV2
export struct StatTile {
  @Param value: string = '0';
  @Param label: Resource = $r('app.string.profile_stat_trips');

  build() {
    Column({ space: 4 }) {
      Text(this.value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}