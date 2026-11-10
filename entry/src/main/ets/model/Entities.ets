/**
 * 领域模型。
 * V2 状态管理：实体使用 @ObservedV2 + @Trace，保证跨组件引用同一实例时字段变化可被观测。
 */
export enum SyncState {
  SYNCED = 0,
  PENDING = 1
}

export enum TripStatus {
  PLANNED = 'planned',
  ONGOING = 'ongoing',
  FINISHED = 'finished'
}

export enum MemberRole {
  OWNER = 'owner',
  MEMBER = 'member'
}

export enum ExpenseCategory {
  FOOD = 'food',
  TRANSPORT = 'transport',
  STAY = 'stay',
  TICKET = 'ticket',
  SHOPPING = 'shopping',
  OTHER = 'other'
}

export const EXPENSE_CATEGORIES: string[] = [
  ExpenseCategory.FOOD,
  ExpenseCategory.TRANSPORT,
  ExpenseCategory.STAY,
  ExpenseCategory.TICKET,
  ExpenseCategory.SHOPPING,
  ExpenseCategory.OTHER
];

@ObservedV2
export class UserProfile {
  public id: string = '';
  @Trace public nickname: string = '';
  @Trace public avatarUri: string = '';
  public createdAt: number = 0;
}

@ObservedV2
export class Trip {
  public id: string = '';
  @Trace public title: string = '';
  @Trace public destination: string = '';
  @Trace public startDate: number = 0;
  @Trace public endDate: number = 0;
  @Trace public note: string = '';
  @Trace public coverUri: string = '';
  public ownerId: string = '';
  public inviteCode: string = '';
  public createdAt: number = 0;
  public updatedAt: number = 0;
  public syncState: number = SyncState.PENDING;
  @Trace public memberCount: number = 0;
  @Trace public momentCount: number = 0;
}

@ObservedV2
export class TripMember {
  public id: string = '';
  public tripId: string = '';
  public userId: string = '';
  @Trace public name: string = '';
  public role: string = MemberRole.MEMBER;
  public joinedAt: number = 0;
}

@ObservedV2
export class MomentMedia {
  public id: string = '';
  public momentId: string = '';
  @Trace public uri: string = '';
  public mediaType: string = 'image';
  public sortIndex: number = 0;
}

@ObservedV2
export class Moment {
  public id: string = '';
  public tripId: string = '';
  @Trace public dayIndex: number = 0;
  @Trace public content: string = '';
  @Trace public locationName: string = '';
  @Trace public latitude: number = 0;
  @Trace public longitude: number = 0;
  public createdAt: number = 0;
  public updatedAt: number = 0;
  public syncState: number = SyncState.PENDING;
  @Trace public media: MomentMedia[] = [];
}

@ObservedV2
export class Expense {
  public id: string = '';
  public tripId: string = '';
  @Trace public amount: number = 0;
  @Trace public category: string = ExpenseCategory.OTHER;
  @Trace public note: string = '';
  @Trace public spentAt: number = 0;
  public createdAt: number = 0;
  public syncState: number = SyncState.PENDING;
}

@ObservedV2
export class ChecklistItem {
  public id: string = '';
  public tripId: string = '';
  @Trace public title: string = '';
  @Trace public done: boolean = false;
  public createdAt: number = 0;
}

@ObservedV2
export class Footprint {
  public id: string = '';
  public tripId: string = '';
  @Trace public placeName: string = '';
  @Trace public city: string = '';
  @Trace public latitude: number = 0;
  @Trace public longitude: number = 0;
  @Trace public note: string = '';
  @Trace public visitedAt: number = 0;
  public createdAt: number = 0;
}

/**
 * 统计快照，供「我的」页与同步页展示。
 */
export class AppStats {
  public tripCount: number = 0;
  public momentCount: number = 0;
  public footprintCount: number = 0;
  public expenseCount: number = 0;
  public cityCount: number = 0;
  public pendingSyncCount: number = 0;
}