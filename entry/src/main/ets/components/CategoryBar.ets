import { CategoryStat } from '../viewmodel/ExpenseViewModel';
import { formatMoney } from '../utils/DateUtil';
import { categoryIcon, categoryLabel } from '../utils/CategoryUtil';

@ComponentV2
export struct CategoryBar {
  @Param stat: CategoryStat = new CategoryStat();

  private barWidth(): string {
    if (this.stat.amount <= 0) {
      return '0%';
    }
    const percent: number = Math.max(this.stat.ratio * 100, 6);
    return percent.toFixed(1) + '%';
  }

  build() {
    Row({ space: 10 }) {
      Text(categoryIcon(this.stat.category))
        .fontSize(17)
        .width(32)
        .height(32)
        .borderRadius(10)
        .backgroundColor($r('app.color.page_bg'))
        .textAlign(TextAlign.Center)

      Column({ space: 6 }) {
        Row() {
          Text(categoryLabel(this.stat.category))
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
          Text('  ' + this.stat.count + ' 笔')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
          Blank()
          Text('¥ ' + formatMoney(this.stat.amount))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')

        Row() {
          Row()
            .width(this.barWidth())
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.stat.color)
        }
        .width('100%')
        .height(6)
        .borderRadius(3)
        .backgroundColor('#F1F3F7')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}