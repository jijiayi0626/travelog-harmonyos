import { AppStorageV2 } from '@kit.ArkUI';
import { AppRouter, RouteName, TripDetailParam, TripEditParam, MomentEditParam, ExpenseEditParam, ChecklistParam, MembersParam, EmptyParam } from '../common/Routes';
import { UserSession } from '../service/UserSession';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { TripListTab } from '../view/TripListTab';
import { FootprintTab } from '../view/FootprintTab';
import { ExpenseTab } from '../view/ExpenseTab';
import { ProfileTab } from '../view/ProfileTab';
import { TripDetailPage } from '../pages/TripDetailPage';
import { TripEditPage } from '../pages/TripEditPage';
import { MomentEditPage } from '../pages/MomentEditPage';
import { ExpenseEditPage } from '../pages/ExpenseEditPage';
import { ChecklistPage } from '../pages/ChecklistPage';
import { MembersPage } from '../pages/MembersPage';
import { FootprintEditPage } from '../pages/FootprintEditPage';
import { AccountPage } from '../pages/AccountPage';
import { SyncPage } from '../pages/SyncPage';

@Entry
@ComponentV2
struct Index {
  @Local currentIndex: number = 0;
  @Local session: UserSession = AppStorageV2.connect(UserSession, 'UserSession', () => new UserSession())!;

  async aboutToAppear(): Promise<void> {
    const profile = await RepositoryProvider.get().getProfile();
    this.session.userId = profile.id;
    this.session.nickname = profile.nickname;
    this.session.avatarUri = profile.avatarUri;
    this.session.accountType = 'local';
  }

  @Builder
  PageMap(name: string, param: Object) {
    if (name === RouteName.TRIP_DETAIL) {
      TripDetailPage({ param: param as TripDetailParam })
    } else if (name === RouteName.TRIP_EDIT) {
      TripEditPage({ param: param as TripEditParam })
    } else if (name === RouteName.MOMENT_EDIT) {
      MomentEditPage({ param: param as MomentEditParam })
    } else if (name === RouteName.EXPENSE_EDIT) {
      ExpenseEditPage({ param: param as ExpenseEditParam })
    } else if (name === RouteName.CHECKLIST) {
      ChecklistPage({ param: param as ChecklistParam })
    } else if (name === RouteName.MEMBERS) {
      MembersPage({ param: param as MembersParam })
    } else if (name === RouteName.FOOTPRINT_EDIT) {
      FootprintEditPage({ param: param as EmptyParam })
    } else if (name === RouteName.ACCOUNT) {
      AccountPage({ param: param as EmptyParam })
    } else if (name === RouteName.SYNC) {
      SyncPage({ param: param as EmptyParam })
    }
  }

  @Builder
  TabBarBuilder(index: number, icon: string, label: Resource) {
    Column({ space: 3 }) {
      Text(icon)
        .fontSize(19)
        .opacity(this.currentIndex === index ? 1 : 0.45)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? $r('app.color.primary') : $r('app.color.text_tertiary'))
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(AppRouter.getStack()) {
      Column() {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            TripListTab()
          }
          .tabBar(this.TabBarBuilder(0, '🧭', $r('app.string.tab_trips')))

          TabContent() {
            FootprintTab()
          }
          .tabBar(this.TabBarBuilder(1, '📍', $r('app.string.tab_footprints')))

          TabContent() {
            ExpenseTab()
          }
          .tabBar(this.TabBarBuilder(2, '💰', $r('app.string.tab_expenses')))

          TabContent() {
            ProfileTab()
          }
          .tabBar(this.TabBarBuilder(3, '👤', $r('app.string.tab_profile')))
        }
        .barHeight(56)
        .barBackgroundColor($r('app.color.card_bg'))
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
        .scrollable(false)
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.page_bg'))
  }
}