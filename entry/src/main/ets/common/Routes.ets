/**
 * 路由表与页面参数。
 * 统一使用 Navigation + NavDestination，不使用旧版 Router。
 */
export class RouteName {
  static readonly TRIP_DETAIL: string = 'tripDetail';
  static readonly TRIP_EDIT: string = 'tripEdit';
  static readonly MOMENT_EDIT: string = 'momentEdit';
  static readonly EXPENSE_EDIT: string = 'expenseEdit';
  static readonly CHECKLIST: string = 'checklist';
  static readonly MEMBERS: string = 'members';
  static readonly FOOTPRINT_EDIT: string = 'footprintEdit';
  static readonly ACCOUNT: string = 'account';
  static readonly SYNC: string = 'sync';
}

export interface TripDetailParam {
  tripId: string;
}

export interface TripEditParam {
  tripId: string;
}

export interface MomentEditParam {
  tripId: string;
  momentId: string;
}

export interface ExpenseEditParam {
  tripId: string;
  expenseId: string;
}

export interface ChecklistParam {
  tripId: string;
}

export interface MembersParam {
  tripId: string;
}

export interface EmptyParam {
  from: string;
}

export class AppRouter {
  private static pathStack: NavPathStack = new NavPathStack();

  static getStack(): NavPathStack {
    return AppRouter.pathStack;
  }

  static push(name: string, param: Object): void {
    AppRouter.pathStack.pushPathByName(name, param);
  }

  static pop(): void {
    AppRouter.pathStack.pop();
  }

  static popToRoot(): void {
    AppRouter.pathStack.clear();
  }
}