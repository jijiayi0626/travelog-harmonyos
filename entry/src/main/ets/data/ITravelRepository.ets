import { AppStats, ChecklistItem, Expense, Footprint, Moment, Trip, TripMember, UserProfile } from '../model/Entities';

/**
 * 数据访问契约。
 * 本地实现：RdbTravelRepository（SQLite）。
 * 云端接入：实现同一接口的 RemoteTravelRepository，并在 RepositoryProvider 中切换，页面无需改动。
 */
export interface ITravelRepository {
  // 旅行
  listTrips(): Promise<Trip[]>;
  getTrip(id: string): Promise<Trip | undefined>;
  saveTrip(trip: Trip): Promise<Trip>;
  deleteTrip(id: string): Promise<void>;

  // 图文记录
  listMoments(tripId: string): Promise<Moment[]>;
  listAllMoments(): Promise<Moment[]>;
  saveMoment(moment: Moment): Promise<Moment>;
  deleteMoment(id: string): Promise<void>;

  // 记账
  listExpenses(tripId: string): Promise<Expense[]>;
  listAllExpenses(): Promise<Expense[]>;
  saveExpense(expense: Expense): Promise<Expense>;
  deleteExpense(id: string): Promise<void>;

  // 行前清单
  listChecklist(tripId: string): Promise<ChecklistItem[]>;
  saveChecklistItem(item: ChecklistItem): Promise<ChecklistItem>;
  deleteChecklistItem(id: string): Promise<void>;

  // 足迹打卡
  listFootprints(): Promise<Footprint[]>;
  saveFootprint(item: Footprint): Promise<Footprint>;
  deleteFootprint(id: string): Promise<void>;

  // 旅伴
  listMembers(tripId: string): Promise<TripMember[]>;
  addMember(tripId: string, name: string): Promise<TripMember>;
  removeMember(id: string): Promise<void>;

  // 账号档案
  getProfile(): Promise<UserProfile>;
  saveProfile(profile: UserProfile): Promise<void>;

  // 统计
  stats(): Promise<AppStats>;
}