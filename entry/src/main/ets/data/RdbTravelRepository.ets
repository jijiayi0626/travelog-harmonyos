import { util } from '@kit.ArkTS';
import { relationalStore } from '@kit.ArkData';
import {
  AppStats,
  ChecklistItem,
  Expense,
  Footprint,
  MemberRole,
  Moment,
  MomentMedia,
  SyncState,
  Trip,
  TripMember,
  UserProfile
} from '../model/Entities';
import { DatabaseHelper } from './DatabaseHelper';
import { ITravelRepository } from './ITravelRepository';

/**
 * 基于 relationalStore 的本地实现。所有写操作都将 sync_state 置为 PENDING，
 * 供后续 SyncService 增量推送。
 */
export class RdbTravelRepository implements ITravelRepository {

  private async store(): Promise<relationalStore.RdbStore> {
    return await DatabaseHelper.getStore();
  }

  private async countSql(sql: string, args: Array<relationalStore.ValueType>): Promise<number> {
    const db: relationalStore.RdbStore = await this.store();
    const rs: relationalStore.ResultSet = await db.querySql(sql, args);
    let value: number = 0;
    if (rs.goToFirstRow()) {
      value = rs.getLong(0);
    }
    rs.close();
    return value;
  }

  // ---------------- 旅行 ----------------

  async listTrips(): Promise<Trip[]> {
    const db: relationalStore.RdbStore = await this.store();
    const sql: string = `SELECT t.*,
      (SELECT COUNT(*) FROM moments m WHERE m.trip_id = t.id) AS moment_count,
      (SELECT COUNT(*) FROM members mm WHERE mm.trip_id = t.id) AS member_count
      FROM trips t ORDER BY t.start_date DESC, t.created_at DESC`;
    const rs: relationalStore.ResultSet = await db.querySql(sql);
    const list: Trip[] = [];
    while (rs.goToNextRow()) {
      const trip: Trip = this.readTrip(rs);
      trip.momentCount = rs.getLong(rs.getColumnIndex('moment_count'));
      trip.memberCount = rs.getLong(rs.getColumnIndex('member_count'));
      list.push(trip);
    }
    rs.close();
    return list;
  }

  async getTrip(id: string): Promise<Trip | undefined> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    const rs: relationalStore.ResultSet = await db.querySql('SELECT * FROM trips WHERE id = ?', args);
    let trip: Trip | undefined = undefined;
    if (rs.goToFirstRow()) {
      trip = this.readTrip(rs);
    }
    rs.close();
    if (trip !== undefined) {
      trip.momentCount = await this.countSql('SELECT COUNT(*) FROM moments WHERE trip_id = ?', args);
      trip.memberCount = await this.countSql('SELECT COUNT(*) FROM members WHERE trip_id = ?', args);
    }
    return trip;
  }

  async saveTrip(trip: Trip): Promise<Trip> {
    const db: relationalStore.RdbStore = await this.store();
    const now: number = Date.now();
    if (trip.id === '') {
      trip.id = util.generateRandomUUID(true);
      trip.createdAt = now;
      trip.updatedAt = now;
      if (trip.inviteCode === '') {
        trip.inviteCode = trip.id.substring(0, 6).toUpperCase();
      }
      trip.syncState = SyncState.PENDING;
      await db.insert('trips', this.tripToBucket(trip));
      return trip;
    }
    trip.updatedAt = now;
    trip.syncState = SyncState.PENDING;
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('trips');
    predicates.equalTo('id', trip.id);
    await db.update(this.tripToBucket(trip), predicates);
    return trip;
  }

  async deleteTrip(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM moment_media WHERE moment_id IN (SELECT id FROM moments WHERE trip_id = ?)', args);
    await db.execute('DELETE FROM moments WHERE trip_id = ?', args);
    await db.execute('DELETE FROM members WHERE trip_id = ?', args);
    await db.execute('DELETE FROM expenses WHERE trip_id = ?', args);
    await db.execute('DELETE FROM checklist WHERE trip_id = ?', args);
    await db.execute('DELETE FROM footprints WHERE trip_id = ?', args);
    await db.execute('DELETE FROM trips WHERE id = ?', args);
  }

  private readTrip(rs: relationalStore.ResultSet): Trip {
    const trip: Trip = new Trip();
    trip.id = rs.getString(rs.getColumnIndex('id'));
    trip.title = rs.getString(rs.getColumnIndex('title'));
    trip.destination = rs.getString(rs.getColumnIndex('destination'));
    trip.startDate = rs.getLong(rs.getColumnIndex('start_date'));
    trip.endDate = rs.getLong(rs.getColumnIndex('end_date'));
    trip.note = rs.getString(rs.getColumnIndex('note'));
    trip.coverUri = rs.getString(rs.getColumnIndex('cover_uri'));
    trip.ownerId = rs.getString(rs.getColumnIndex('owner_id'));
    trip.inviteCode = rs.getString(rs.getColumnIndex('invite_code'));
    trip.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
    trip.updatedAt = rs.getLong(rs.getColumnIndex('updated_at'));
    trip.syncState = rs.getLong(rs.getColumnIndex('sync_state'));
    return trip;
  }

  private tripToBucket(trip: Trip): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {
      'id': trip.id,
      'title': trip.title,
      'destination': trip.destination,
      'start_date': trip.startDate,
      'end_date': trip.endDate,
      'note': trip.note,
      'cover_uri': trip.coverUri,
      'owner_id': trip.ownerId,
      'invite_code': trip.inviteCode,
      'created_at': trip.createdAt,
      'updated_at': trip.updatedAt,
      'sync_state': trip.syncState
    };
    return bucket;
  }

  // ---------------- 图文记录 ----------------

  async listMoments(tripId: string): Promise<Moment[]> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [tripId];
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM moments WHERE trip_id = ? ORDER BY day_index ASC, created_at ASC', args);
    const list: Moment[] = [];
    while (rs.goToNextRow()) {
      list.push(this.readMoment(rs));
    }
    rs.close();
    for (const moment of list) {
      moment.media = await this.loadMedia(moment.id);
    }
    return list;
  }

  async listAllMoments(): Promise<Moment[]> {
    const db: relationalStore.RdbStore = await this.store();
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM moments ORDER BY created_at DESC');
    const list: Moment[] = [];
    while (rs.goToNextRow()) {
      list.push(this.readMoment(rs));
    }
    rs.close();
    for (const moment of list) {
      moment.media = await this.loadMedia(moment.id);
    }
    return list;
  }

  async saveMoment(moment: Moment): Promise<Moment> {
    const db: relationalStore.RdbStore = await this.store();
    const now: number = Date.now();
    if (moment.id === '') {
      moment.id = util.generateRandomUUID(true);
      moment.createdAt = now;
    }
    moment.updatedAt = now;
    moment.syncState = SyncState.PENDING;
    const bucket: relationalStore.ValuesBucket = {
      'id': moment.id,
      'trip_id': moment.tripId,
      'day_index': moment.dayIndex,
      'content': moment.content,
      'location_name': moment.locationName,
      'latitude': moment.latitude,
      'longitude': moment.longitude,
      'created_at': moment.createdAt,
      'updated_at': moment.updatedAt,
      'sync_state': moment.syncState
    };
    await db.insert('moments', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

    const args: Array<relationalStore.ValueType> = [moment.id];
    await db.execute('DELETE FROM moment_media WHERE moment_id = ?', args);
    for (let i = 0; i < moment.media.length; i++) {
      const media: MomentMedia = moment.media[i];
      media.id = util.generateRandomUUID(true);
      media.momentId = moment.id;
      media.sortIndex = i;
      const mediaBucket: relationalStore.ValuesBucket = {
        'id': media.id,
        'moment_id': media.momentId,
        'uri': media.uri,
        'media_type': media.mediaType,
        'sort_index': media.sortIndex
      };
      await db.insert('moment_media', mediaBucket);
    }
    return moment;
  }

  async deleteMoment(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM moment_media WHERE moment_id = ?', args);
    await db.execute('DELETE FROM moments WHERE id = ?', args);
  }

  private readMoment(rs: relationalStore.ResultSet): Moment {
    const moment: Moment = new Moment();
    moment.id = rs.getString(rs.getColumnIndex('id'));
    moment.tripId = rs.getString(rs.getColumnIndex('trip_id'));
    moment.dayIndex = rs.getLong(rs.getColumnIndex('day_index'));
    moment.content = rs.getString(rs.getColumnIndex('content'));
    moment.locationName = rs.getString(rs.getColumnIndex('location_name'));
    moment.latitude = rs.getDouble(rs.getColumnIndex('latitude'));
    moment.longitude = rs.getDouble(rs.getColumnIndex('longitude'));
    moment.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
    moment.updatedAt = rs.getLong(rs.getColumnIndex('updated_at'));
    moment.syncState = rs.getLong(rs.getColumnIndex('sync_state'));
    return moment;
  }

  private async loadMedia(momentId: string): Promise<MomentMedia[]> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [momentId];
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM moment_media WHERE moment_id = ? ORDER BY sort_index ASC', args);
    const list: MomentMedia[] = [];
    while (rs.goToNextRow()) {
      const media: MomentMedia = new MomentMedia();
      media.id = rs.getString(rs.getColumnIndex('id'));
      media.momentId = rs.getString(rs.getColumnIndex('moment_id'));
      media.uri = rs.getString(rs.getColumnIndex('uri'));
      media.mediaType = rs.getString(rs.getColumnIndex('media_type'));
      media.sortIndex = rs.getLong(rs.getColumnIndex('sort_index'));
      list.push(media);
    }
    rs.close();
    return list;
  }

  // ---------------- 记账 ----------------

  async listExpenses(tripId: string): Promise<Expense[]> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [tripId];
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM expenses WHERE trip_id = ? ORDER BY spent_at DESC, created_at DESC', args);
    const list: Expense[] = [];
    while (rs.goToNextRow()) {
      list.push(this.readExpense(rs));
    }
    rs.close();
    return list;
  }

  async listAllExpenses(): Promise<Expense[]> {
    const db: relationalStore.RdbStore = await this.store();
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM expenses ORDER BY spent_at DESC, created_at DESC');
    const list: Expense[] = [];
    while (rs.goToNextRow()) {
      list.push(this.readExpense(rs));
    }
    rs.close();
    return list;
  }

  async saveExpense(expense: Expense): Promise<Expense> {
    const db: relationalStore.RdbStore = await this.store();
    if (expense.id === '') {
      expense.id = util.generateRandomUUID(true);
    }
    if (expense.createdAt === 0) {
      expense.createdAt = Date.now();
    }
    expense.syncState = SyncState.PENDING;
    const bucket: relationalStore.ValuesBucket = {
      'id': expense.id,
      'trip_id': expense.tripId,
      'amount': expense.amount,
      'category': expense.category,
      'note': expense.note,
      'spent_at': expense.spentAt,
      'created_at': expense.createdAt,
      'sync_state': expense.syncState
    };
    await db.insert('expenses', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    return expense;
  }

  async deleteExpense(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM expenses WHERE id = ?', args);
  }

  private readExpense(rs: relationalStore.ResultSet): Expense {
    const expense: Expense = new Expense();
    expense.id = rs.getString(rs.getColumnIndex('id'));
    expense.tripId = rs.getString(rs.getColumnIndex('trip_id'));
    expense.amount = rs.getDouble(rs.getColumnIndex('amount'));
    expense.category = rs.getString(rs.getColumnIndex('category'));
    expense.note = rs.getString(rs.getColumnIndex('note'));
    expense.spentAt = rs.getLong(rs.getColumnIndex('spent_at'));
    expense.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
    expense.syncState = rs.getLong(rs.getColumnIndex('sync_state'));
    return expense;
  }

  // ---------------- 清单 ----------------

  async listChecklist(tripId: string): Promise<ChecklistItem[]> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [tripId];
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM checklist WHERE trip_id = ? ORDER BY created_at ASC', args);
    const list: ChecklistItem[] = [];
    while (rs.goToNextRow()) {
      const item: ChecklistItem = new ChecklistItem();
      item.id = rs.getString(rs.getColumnIndex('id'));
      item.tripId = rs.getString(rs.getColumnIndex('trip_id'));
      item.title = rs.getString(rs.getColumnIndex('title'));
      item.done = rs.getLong(rs.getColumnIndex('done')) === 1;
      item.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
      list.push(item);
    }
    rs.close();
    return list;
  }

  async saveChecklistItem(item: ChecklistItem): Promise<ChecklistItem> {
    const db: relationalStore.RdbStore = await this.store();
    if (item.id === '') {
      item.id = util.generateRandomUUID(true);
      item.createdAt = Date.now();
    }
    const bucket: relationalStore.ValuesBucket = {
      'id': item.id,
      'trip_id': item.tripId,
      'title': item.title,
      'done': item.done ? 1 : 0,
      'created_at': item.createdAt
    };
    await db.insert('checklist', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    return item;
  }

  async deleteChecklistItem(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM checklist WHERE id = ?', args);
  }

  // ---------------- 足迹 ----------------

  async listFootprints(): Promise<Footprint[]> {
    const db: relationalStore.RdbStore = await this.store();
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM footprints ORDER BY visited_at DESC, created_at DESC');
    const list: Footprint[] = [];
    while (rs.goToNextRow()) {
      const item: Footprint = new Footprint();
      item.id = rs.getString(rs.getColumnIndex('id'));
      item.tripId = rs.getString(rs.getColumnIndex('trip_id'));
      item.placeName = rs.getString(rs.getColumnIndex('place_name'));
      item.city = rs.getString(rs.getColumnIndex('city'));
      item.latitude = rs.getDouble(rs.getColumnIndex('latitude'));
      item.longitude = rs.getDouble(rs.getColumnIndex('longitude'));
      item.note = rs.getString(rs.getColumnIndex('note'));
      item.visitedAt = rs.getLong(rs.getColumnIndex('visited_at'));
      item.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
      list.push(item);
    }
    rs.close();
    return list;
  }

  async saveFootprint(item: Footprint): Promise<Footprint> {
    const db: relationalStore.RdbStore = await this.store();
    if (item.id === '') {
      item.id = util.generateRandomUUID(true);
      item.createdAt = Date.now();
    }
    const bucket: relationalStore.ValuesBucket = {
      'id': item.id,
      'trip_id': item.tripId,
      'place_name': item.placeName,
      'city': item.city,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'note': item.note,
      'visited_at': item.visitedAt,
      'created_at': item.createdAt
    };
    await db.insert('footprints', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    return item;
  }

  async deleteFootprint(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM footprints WHERE id = ?', args);
  }

  // ---------------- 旅伴 ----------------

  async listMembers(tripId: string): Promise<TripMember[]> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [tripId];
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT * FROM members WHERE trip_id = ? ORDER BY joined_at ASC', args);
    const list: TripMember[] = [];
    while (rs.goToNextRow()) {
      const member: TripMember = new TripMember();
      member.id = rs.getString(rs.getColumnIndex('id'));
      member.tripId = rs.getString(rs.getColumnIndex('trip_id'));
      member.userId = rs.getString(rs.getColumnIndex('user_id'));
      member.name = rs.getString(rs.getColumnIndex('name'));
      member.role = rs.getString(rs.getColumnIndex('role'));
      member.joinedAt = rs.getLong(rs.getColumnIndex('joined_at'));
      list.push(member);
    }
    rs.close();
    return list;
  }

  async addMember(tripId: string, name: string): Promise<TripMember> {
    const db: relationalStore.RdbStore = await this.store();
    const member: TripMember = new TripMember();
    member.id = util.generateRandomUUID(true);
    member.tripId = tripId;
    member.userId = 'local-' + member.id.substring(0, 8);
    member.name = name;
    member.role = MemberRole.MEMBER;
    member.joinedAt = Date.now();
    const bucket: relationalStore.ValuesBucket = {
      'id': member.id,
      'trip_id': member.tripId,
      'user_id': member.userId,
      'name': member.name,
      'role': member.role,
      'joined_at': member.joinedAt
    };
    await db.insert('members', bucket);
    return member;
  }

  async removeMember(id: string): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    const args: Array<relationalStore.ValueType> = [id];
    await db.execute('DELETE FROM members WHERE id = ?', args);
  }

  // ---------------- 账号 ----------------

  async getProfile(): Promise<UserProfile> {
    const db: relationalStore.RdbStore = await this.store();
    const rs: relationalStore.ResultSet = await db.querySql('SELECT * FROM profile LIMIT 1');
    const profile: UserProfile = new UserProfile();
    if (rs.goToFirstRow()) {
      profile.id = rs.getString(rs.getColumnIndex('id'));
      profile.nickname = rs.getString(rs.getColumnIndex('nickname'));
      profile.avatarUri = rs.getString(rs.getColumnIndex('avatar_uri'));
      profile.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
    } else {
      profile.id = 'local-user';
      profile.nickname = '我';
      profile.createdAt = Date.now();
      const bucket: relationalStore.ValuesBucket = {
        'id': profile.id,
        'nickname': profile.nickname,
        'avatar_uri': profile.avatarUri,
        'created_at': profile.createdAt
      };
      await db.insert('profile', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }
    rs.close();
    return profile;
  }

  async saveProfile(profile: UserProfile): Promise<void> {
    const db: relationalStore.RdbStore = await this.store();
    if (profile.id === '') {
      profile.id = 'local-user';
    }
    if (profile.createdAt === 0) {
      profile.createdAt = Date.now();
    }
    const bucket: relationalStore.ValuesBucket = {
      'id': profile.id,
      'nickname': profile.nickname,
      'avatar_uri': profile.avatarUri,
      'created_at': profile.createdAt
    };
    await db.insert('profile', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  // ---------------- 统计 ----------------

  async stats(): Promise<AppStats> {
    const stats: AppStats = new AppStats();
    stats.tripCount = await this.countSql('SELECT COUNT(*) FROM trips', []);
    stats.momentCount = await this.countSql('SELECT COUNT(*) FROM moments', []);
    stats.footprintCount = await this.countSql('SELECT COUNT(*) FROM footprints', []);
    stats.expenseCount = await this.countSql('SELECT COUNT(*) FROM expenses', []);
    stats.cityCount = await this.countSql("SELECT COUNT(DISTINCT city) FROM footprints WHERE city <> ''", []);
    const pendingTrips: number = await this.countSql('SELECT COUNT(*) FROM trips WHERE sync_state = 1', []);
    const pendingMoments: number = await this.countSql('SELECT COUNT(*) FROM moments WHERE sync_state = 1', []);
    const pendingExpenses: number = await this.countSql('SELECT COUNT(*) FROM expenses WHERE sync_state = 1', []);
    stats.pendingSyncCount = pendingTrips + pendingMoments + pendingExpenses;
    return stats;
  }
}