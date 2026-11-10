import { AppStorageV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { MomentGroup, TripDetailViewModel } from '../viewmodel/TripDetailViewModel';
import { MomentItem } from '../components/MomentItem';
import { ChecklistRow } from '../components/ChecklistRow';
import { ExpenseRow } from '../components/ExpenseRow';
import { EmptyState } from '../components/EmptyState';
import { Avatar } from '../components/Avatar';
import { AppRefresh } from '../service/AppRefresh';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import {
  AppRouter,
  RouteName,
  TripDetailParam,
  TripEditParam,
  MomentEditParam,
  ExpenseEditParam,
  ChecklistParam,
  MembersParam
} from '../common/Routes';
import { ChecklistItem, Expense, Moment, Trip, TripMember, TripStatus } from '../model/Entities';
import { formatDate, formatMoney, tripDayCount, tripStatusOf } from '../utils/DateUtil';
import { tripStatusColor, tripStatusLabel } from '../utils/CategoryUtil';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct TripDetailPage {
  @Param param: TripDetailParam = { tripId: '' };
  @Local vm: TripDetailViewModel = new TripDetailViewModel();
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;
  @Local tabIndex: number = 0;
  @Local newCheckTitle: string = '';

  private repository: ITravelRepository = RepositoryProvider.get();

  async aboutToAppear(): Promise<void> {
    await this.vm.load(this.param.tripId);
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.vm.load(this.param.tripId);
  }

  @Computed
  get trip(): Trip {
    return this.vm.trip !== undefined ? this.vm.trip : new Trip();
  }

  private status(): TripStatus {
    return tripStatusOf(this.trip.startDate, this.trip.endDate);
  }

  private dateRange(): string {
    if (this.trip.startDate <= 0) {
      return '';
    }
    return formatDate(this.trip.startDate) + ' - ' + formatDate(this.trip.endDate);
  }

  private openEdit(): void {
    const param: TripEditParam = { tripId: this.trip.id };
    AppRouter.push(RouteName.TRIP_EDIT, param);
  }

  private openMoment(momentId: string): void {
    const param: MomentEditParam = { tripId: this.param.tripId, momentId: momentId };
    AppRouter.push(RouteName.MOMENT_EDIT, param);
  }

  private openExpense(expenseId: string): void {
    const param: ExpenseEditParam = { tripId: this.param.tripId, expenseId: expenseId };
    AppRouter.push(RouteName.EXPENSE_EDIT, param);
  }

  private openChecklist(): void {
    const param: ChecklistParam = { tripId: this.param.tripId };
    AppRouter.push(RouteName.CHECKLIST, param);
  }

  private openMembers(): void {
    const param: MembersParam = { tripId: this.param.tripId };
    AppRouter.push(RouteName.MEMBERS, param);
  }

  private async addChecklist(): Promise<void> {
    const title: string = this.newCheckTitle.trim();
    if (title === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    const item: ChecklistItem = new ChecklistItem();
    item.tripId = this.param.tripId;
    item.title = title;
    await this.repository.saveChecklistItem(item);
    this.newCheckTitle = '';
    this.refresh.bump();
  }

  private async toggleChecklist(item: ChecklistItem, done: boolean): Promise<void> {
    item.done = done;
    await this.repository.saveChecklistItem(item);
    this.refresh.bump();
  }

  private async deleteChecklist(item: ChecklistItem): Promise<void> {
    await this.repository.deleteChecklistItem(item.id);
    this.refresh.bump();
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
          this.deleteTrip();
        }
      }
    });
  }

  private async deleteTrip(): Promise<void> {
    await this.repository.deleteTrip(this.param.tripId);
    this.refresh.bump();
    showToast(this.getUIContext(), $r('app.string.toast_deleted'));
    AppRouter.pop();
  }

  @Builder
  SubTabBar(index: number, label: Resource) {
    Text(label)
      .fontSize(14)
      .fontColor(this.tabIndex === index ? $r('app.color.primary') : $r('app.color.text_secondary'))
      .fontWeight(this.tabIndex === index ? FontWeight.Medium : FontWeight.Normal)
      .padding({ top: 10, bottom: 10 })
  }

  @Builder
  Overview() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Text(tripStatusLabel(this.status()))
          .fontSize(10)
          .fontColor($r('app.color.white'))
          .backgroundColor(tripStatusColor(this.status()))
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .margin({ top: 2 })
        Blank()
        Text($r('app.string.action_edit'))
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor('#33FFFFFF')
          .onClick(() => this.openEdit())
      }
      .width('100%')

      Text(this.trip.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.white'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 6 }) {
        Text(this.trip.destination)
          .fontSize(13)
          .fontColor('#DBEAFE')
        if (this.dateRange() !== '') {
          Text('· ' + this.dateRange())
            .fontSize(12)
            .fontColor('#BFDBFE')
        }
        if (tripDayCount(this.trip.startDate, this.trip.endDate) > 0) {
          Text('· ' + tripDayCount(this.trip.startDate, this.trip.endDate) + ' 天')
            .fontSize(12)
            .fontColor('#BFDBFE')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .borderRadius(20)
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      angle: 135,
      colors: [[tripStatusColor(this.status()), 0.0], ['#0F172A', 1.0]]
    })
  }

  @Builder
  QuickStats() {
    Row() {
      Column({ space: 4 }) {
        Text('' + this.vm.moments.length)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text($r('app.string.profile_stat_moments'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('¥' + formatMoney(this.vm.totalExpense))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text($r('app.string.expense_total'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('' + this.vm.checklistDone + '/' + this.vm.checklist.length)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text($r('app.string.checklist_title'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('' + this.vm.members.length)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text($r('app.string.members_title'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  @Builder
  TimelineTab() {
    Column() {
      Row() {
        Text($r('app.string.detail_tab_timeline'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Row({ space: 2 }) {
          Text('＋')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
          Text($r('app.string.moment_add'))
            .fontSize(12)
            .fontColor($r('app.color.primary'))
        }
        .onClick(() => this.openMoment(''))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      if (this.vm.groupedMoments.length === 0) {
        EmptyState({
          icon: '📖',
          title: $r('app.string.empty_moments'),
          hint: $r('app.string.empty_moments_hint')
        })
      } else {
        List({ space: 10 }) {
          ForEach(this.vm.groupedMoments, (group: MomentGroup) => {
            ListItem() {
              Row({ space: 8 }) {
                Text($r('app.string.moment_day_format', group.dayIndex))
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.primary'))
                Divider()
                  .strokeWidth(0.5)
                  .color($r('app.color.divider'))
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 2 })
            }

            ForEach(group.moments, (moment: Moment) => {
              ListItem() {
                MomentItem({ moment: moment })
                  .onClick(() => this.openMoment(moment.id))
              }
            }, (moment: Moment) => moment.id)
          }, (group: MomentGroup) => 'day-' + group.dayIndex)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ExpenseTabContent() {
    Column() {
      Row() {
        Text($r('app.string.expense_total'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        Text('  ¥' + formatMoney(this.vm.totalExpense))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Row({ space: 2 }) {
          Text('＋')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
          Text($r('app.string.expense_add'))
            .fontSize(12)
            .fontColor($r('app.color.primary'))
        }
        .onClick(() => this.openExpense(''))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 6 })

      if (this.vm.expenses.length === 0) {
        EmptyState({
          icon: '🧾',
          title: $r('app.string.empty_expenses'),
          hint: $r('app.string.expense_add')
        })
      } else {
        List({ space: 8 }) {
          ForEach(this.vm.expenses, (expense: Expense) => {
            ListItem() {
              ExpenseRow({
                expense: expense,
                onClick: () => this.openExpense(expense.id)
              })
            }
          }, (expense: Expense) => expense.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ChecklistTabContent() {
    Column() {
      Row({ space: 8 }) {
        TextInput({ placeholder: $r('app.string.checklist_add_placeholder'), text: this.newCheckTitle })
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(19)
          .onChange((value: string) => {
            this.newCheckTitle = value;
          })
        Button($r('app.string.action_add'))
          .height(38)
          .fontSize(13)
          .borderRadius(19)
          .backgroundColor($r('app.color.primary'))
          .onClick(() => this.addChecklist())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 6 })

      Row() {
        Text($r('app.string.checklist_progress_format', this.vm.checklistDone, this.vm.checklist.length))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text($r('app.string.action_edit'))
          .fontSize(12)
          .fontColor($r('app.color.primary'))
          .onClick(() => this.openChecklist())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })

      if (this.vm.checklist.length === 0) {
        EmptyState({
          icon: '🧳',
          title: $r('app.string.empty_checklist'),
          hint: $r('app.string.checklist_tip')
        })
      } else {
        List({ space: 8 }) {
          ForEach(this.vm.checklist, (item: ChecklistItem) => {
            ListItem() {
              ChecklistRow({
                item: item,
                onToggle: (done: boolean) => this.toggleChecklist(item, done),
                onDelete: () => this.deleteChecklist(item)
              })
            }
          }, (item: ChecklistItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MembersTabContent() {
    Column() {
      Row() {
        Text($r('app.string.members_title'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Row({ space: 2 }) {
          Text('＋')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
          Text($r('app.string.members_add'))
            .fontSize(12)
            .fontColor($r('app.color.primary'))
        }
        .onClick(() => this.openMembers())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 6 })

      if (this.vm.members.length === 0) {
        EmptyState({
          icon: '🧑‍🤝‍🧑',
          title: $r('app.string.empty_members'),
          hint: $r('app.string.profile_members_hint')
        })
      } else {
        List({ space: 8 }) {
          ForEach(this.vm.members, (member: TripMember) => {
            ListItem() {
              Row({ space: 12 }) {
                Avatar({ name: member.name, size: 38 })
                Column({ space: 2 }) {
                  Text(member.name)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                  Text(member.role === 'owner' ? $r('app.string.members_role_owner') : $r('app.string.members_role_member'))
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(14)
            }
          }, (member: TripMember) => member.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        if (this.vm.loading) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color($r('app.color.primary'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.trip === undefined) {
          EmptyState({
            icon: '🧭',
            title: $r('app.string.empty_trips'),
            hint: $r('app.string.empty_trips_hint')
          })
        } else {
          this.Overview()
          this.QuickStats()

          Tabs({ index: this.tabIndex, barPosition: BarPosition.Start }) {
            TabContent() {
              this.TimelineTab()
            }
            .tabBar(this.SubTabBar(0, $r('app.string.detail_tab_timeline')))

            TabContent() {
              this.ExpenseTabContent()
            }
            .tabBar(this.SubTabBar(1, $r('app.string.detail_tab_expense')))

            TabContent() {
              this.ChecklistTabContent()
            }
            .tabBar(this.SubTabBar(2, $r('app.string.detail_tab_checklist')))

            TabContent() {
              this.MembersTabContent()
            }
            .tabBar(this.SubTabBar(3, $r('app.string.detail_tab_members')))
          }
          .barHeight(44)
          .barBackgroundColor($r('app.color.card_bg'))
          .layoutWeight(1)
          .onChange((index: number) => {
            this.tabIndex = index;
          })

          Row() {
            Text($r('app.string.action_delete'))
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .onClick(() => this.confirmDelete())
            Blank()
            if (this.trip.inviteCode !== '') {
              Text($r('app.string.members_invite_format', this.trip.inviteCode))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .onClick(() => this.openMembers())
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 0, right: 0, top: 8 })
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.trip_detail_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}