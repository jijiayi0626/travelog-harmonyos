@ComponentV2
export struct Avatar {
  @Param name: string = '';
  @Param avatarUri: string = '';
  @Param size: number = 44;

  build() {
    Stack() {
      if (this.avatarUri !== '') {
        Image(this.avatarUri)
          .width(this.size)
          .height(this.size)
          .borderRadius(this.size / 2)
          .objectFit(ImageFit.Cover)
      } else {
        Text(this.name.length > 0 ? this.name.substring(0, 1) : '?')
          .width(this.size)
          .height(this.size)
          .borderRadius(this.size / 2)
          .backgroundColor($r('app.color.primary_light'))
          .fontColor($r('app.color.primary'))
          .fontSize(this.size * 0.42)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.size)
    .height(this.size)
  }
}