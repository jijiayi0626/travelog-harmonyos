import { AppStorageV2 } from '@kit.ArkUI';
import { ExpenseEditParam, AppRouter } from '../common/Routes';
import { Expense, EXPENSE_CATEGORIES, ExpenseCategory } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { categoryColor, categoryIcon, categoryLabel } from '../utils/CategoryUtil';
import { formatDate, startOfDay } from '../utils/DateUtil';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct ExpenseEditPage {
  @Param param: ExpenseEditParam = { tripId: '', expenseId: '' };
  @Local amountText: string = '';
  @Local note: string = '';
  @Local category: string = ExpenseCategory.FOOD;
  @Local spentAt: number = Date.now();
  @Local loading: boolean = true;
  @Local saving: boolean = false;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();
  private expense: Expense = new Expense();

  async aboutToAppear(): Promise<void> {
    if (this.param.expenseId !== '') {
      const expenses: Expense[] = await this.repository.listExpenses(this.param.tripId);
      for (const item of expenses) {
        if (item.id === this.param.expenseId) {
          this.expense = item;
          this.amountText = item.amount > 0 ? item.amount.toString() : '';
          this.note = item.note;
          this.category = item.category;
          this.spentAt = item.spentAt;
          break;
        }
      }
    }
    this.loading = false;
  }

  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: new Date(this.spentAt > 0 ? this.spentAt : Date.now()),
      onDateAccept: (value: Date) => {
        this.spentAt = startOfDay(value.getTime());
      }
    });
  }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    const amount: number = Number.parseFloat(this.amountText);
    if (isNaN(amount) || amount <= 0) {
      showToast(this.getUIContext(), $r('app.string.toast_amount_invalid'));
      return;
    }
    this.saving = true;
    this.expense.tripId = this.param.tripId;
    this.expense.amount = amount;
    this.expense.category = this.category;
    this.expense.note = this.note.trim();
    this.expense.spentAt = this.spentAt;
    await this.repository.saveExpense(this.expense);
    this.refresh.bump();
    this.saving = false;
    showToast(this.getUIContext(), $r('app.string.toast_saved'));
    AppRouter.pop();
  }

  private confirmDelete(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.dialog_delete_title'),
      message: $r('app.string.dialog_delete_msg'),
      primaryButton: {
        value: $r('app.string.action_cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: $r('app.string.action_delete'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.deleteExpense();
        }
      }
    });
  }

  private async deleteExpense(): Promise<void> {
    await this.repository.deleteExpense(this.param.expenseId);
    this.refresh.bump();
    showToast(this.getUIContext(), $r('app.string.toast_deleted'));
    AppRouter.pop();
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 8 }) {
          Text($r('app.string.expense_amount_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row({ space: 6 }) {
            Text('¥')
              .fontSize(24)
              .fontColor($r('app.color.text_primary'))
            TextInput({ placeholder: $r('app.string.expense_amount_placeholder'), text: this.amountText })
              .type(InputType.NUMBER_DECIMAL)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.amountText = value;
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Text($r('app.string.expense_category_label'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(EXPENSE_CATEGORIES, (item: string) => {
              Row({ space: 4 }) {
                Text(categoryIcon(item))
                  .fontSize(14)
                Text(categoryLabel(item))
                  .fontSize(13)
                  .fontColor(this.category === item ? $r('app.color.white') : $r('app.color.text_primary'))
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(18)
              .backgroundColor(this.category === item ? categoryColor(item) : $r('app.color.page_bg'))
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.category = item;
              })
            }, (item: string) => item)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Row() {
            Text($r('app.string.expense_date_label'))
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text(formatDate(this.spentAt))
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text('  ›')
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .height(40)
          .onClick(() => this.pickDate())

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          TextInput({ placeholder: $r('app.string.expense_note_placeholder'), text: this.note })
            .height(44)
            .fontSize(14)
            .backgroundColor($r('app.color.page_bg'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.note = value;
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Button($r('app.string.action_save'))
          .width('100%')
          .height(46)
          .fontSize(15)
          .borderRadius(23)
          .backgroundColor($r('app.color.primary'))
          .enabled(!this.saving)
          .onClick(() => this.save())

        if (this.param.expenseId !== '') {
          Button($r('app.string.action_delete'))
            .width('100%')
            .height(44)
            .fontSize(14)
            .borderRadius(22)
            .backgroundColor($r('app.color.card_bg'))
            .fontColor($r('app.color.danger'))
            .onClick(() => this.confirmDelete())
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })
    }
    .title(this.param.expenseId === '' ? $r('app.string.expense_add') : $r('app.string.expense_edit'))
    .backgroundColor($r('app.color.page_bg'))
  }
}