import { Expense } from '../model/Entities';
import { formatDateCn, formatMoney } from '../utils/DateUtil';
import { categoryIcon, categoryLabel } from '../utils/CategoryUtil';

@ComponentV2
export struct ExpenseRow {
  @Param expense: Expense = new Expense();
  @Event onClick: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(categoryIcon(this.expense.category))
        .fontSize(20)
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor($r('app.color.page_bg'))
        .textAlign(TextAlign.Center)

      Column({ space: 3 }) {
        Text(categoryLabel(this.expense.category))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
        Text(this.expense.note !== '' ? this.expense.note : formatDateCn(this.expense.spentAt))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('¥ ' + formatMoney(this.expense.amount))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => this.onClick())
  }
}