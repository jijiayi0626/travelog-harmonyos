import { ChecklistItem } from '../model/Entities';

@ComponentV2
export struct ChecklistRow {
  @Param item: ChecklistItem = new ChecklistItem();
  @Event onToggle: (done: boolean) => void = (done: boolean) => {};
  @Event onDelete: () => void = () => {};

  build() {
    Row({ space: 8 }) {
      Checkbox({ name: this.item.id, group: 'checklist' })
        .select(this.item.done)
        .selectedColor($r('app.color.primary'))
        .width(22)
        .height(22)
        .onChange((value: boolean) => this.onToggle(value))

      Text(this.item.title)
        .fontSize(15)
        .fontColor(this.item.done ? $r('app.color.text_tertiary') : $r('app.color.text_primary'))
        .decoration({ type: this.item.done ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)
        .onClick(() => this.onToggle(!this.item.done))

      Text('×')
        .fontSize(18)
        .fontColor($r('app.color.text_tertiary'))
        .padding({ left: 8, right: 4 })
        .onClick(() => this.onDelete())
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }
}