import { AppStorageV2 } from '@kit.ArkUI';
import { ExpenseViewModel, CategoryStat } from '../viewmodel/ExpenseViewModel';
import { ExpenseRow } from '../components/ExpenseRow';
import { CategoryBar } from '../components/CategoryBar';
import { EmptyState } from '../components/EmptyState';
import { AppRefresh } from '../service/AppRefresh';
import { AppRouter, RouteName, ExpenseEditParam } from '../common/Routes';
import { Expense } from '../model/Entities';
import { formatMoney } from '../utils/DateUtil';

@ComponentV2
export struct ExpenseTab {
  @Local vm: ExpenseViewModel = new ExpenseViewModel();
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  aboutToAppear(): void {
    this.vm.loadAll();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.vm.loadAll();
  }

  private openCreate(): void {
    const param: ExpenseEditParam = { tripId: '', expenseId: '' };
    AppRouter.push(RouteName.EXPENSE_EDIT, param);
  }

  private openEdit(expense: Expense): void {
    const param: ExpenseEditParam = { tripId: expense.tripId, expenseId: expense.id };
    AppRouter.push(RouteName.EXPENSE_EDIT, param);
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text($r('app.string.tab_expenses'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text($r('app.string.expense_all_trips'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button({ type: ButtonType.Normal }) {
          Row({ space: 4 }) {
            Text('＋')
              .fontSize(15)
              .fontColor($r('app.color.white'))
            Text($r('app.string.expense_add'))
              .fontSize(13)
              .fontColor($r('app.color.white'))
          }
        }
        .backgroundColor($r('app.color.primary'))
        .borderRadius(18)
        .height(36)
        .padding({ left: 14, right: 14 })
        .onClick(() => this.openCreate())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 6 }) {
            Text($r('app.string.expense_total'))
              .fontSize(12)
              .fontColor('#DBEAFE')
            Row({ space: 4 }) {
              Text('¥')
                .fontSize(16)
                .fontColor($r('app.color.white'))
              Text(formatMoney(this.vm.total))
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.white'))
            }
            Text($r('app.string.expense_count_format', this.vm.expenses.length))
              .fontSize(12)
              .fontColor('#DBEAFE')
          }
          .width('100%')
          .padding(18)
          .borderRadius(20)
          .alignItems(HorizontalAlign.Start)
          .linearGradient({
            angle: 135,
            colors: [['#2563EB', 0.0], ['#1E40AF', 1.0]]
          })

          if (this.vm.expenses.length > 0) {
            Column({ space: 4 }) {
              Text($r('app.string.expense_by_category'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              ForEach(this.vm.categoryStats, (stat: CategoryStat) => {
                if (stat.amount > 0) {
                  CategoryBar({ stat: stat })
                }
              }, (stat: CategoryStat) => stat.category)
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
          }

          if (this.vm.expenses.length === 0) {
            EmptyState({
              icon: '🧾',
              title: $r('app.string.empty_expenses'),
              hint: $r('app.string.expense_add')
            })
          } else {
            Column({ space: 8 }) {
              ForEach(this.vm.expenses, (expense: Expense) => {
                ExpenseRow({
                  expense: expense,
                  onClick: () => this.openEdit(expense)
                })
              }, (expense: Expense) => expense.id)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}