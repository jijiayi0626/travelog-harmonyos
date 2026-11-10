import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0001;
const TAG: string = 'TravelDb';
const DB_NAME: string = 'travellog.db';

const CREATE_TRIPS: string = `CREATE TABLE IF NOT EXISTS trips (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  destination TEXT NOT NULL DEFAULT '',
  start_date INTEGER NOT NULL DEFAULT 0,
  end_date INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  cover_uri TEXT NOT NULL DEFAULT '',
  owner_id TEXT NOT NULL DEFAULT '',
  invite_code TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  sync_state INTEGER NOT NULL DEFAULT 1
)`;

const CREATE_MEMBERS: string = `CREATE TABLE IF NOT EXISTS members (
  id TEXT PRIMARY KEY,
  trip_id TEXT NOT NULL DEFAULT '',
  user_id TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'member',
  joined_at INTEGER NOT NULL DEFAULT 0
)`;

const CREATE_MOMENTS: string = `CREATE TABLE IF NOT EXISTS moments (
  id TEXT PRIMARY KEY,
  trip_id TEXT NOT NULL DEFAULT '',
  day_index INTEGER NOT NULL DEFAULT 0,
  content TEXT NOT NULL DEFAULT '',
  location_name TEXT NOT NULL DEFAULT '',
  latitude REAL NOT NULL DEFAULT 0,
  longitude REAL NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  sync_state INTEGER NOT NULL DEFAULT 1
)`;

const CREATE_MOMENT_MEDIA: string = `CREATE TABLE IF NOT EXISTS moment_media (
  id TEXT PRIMARY KEY,
  moment_id TEXT NOT NULL DEFAULT '',
  uri TEXT NOT NULL DEFAULT '',
  media_type TEXT NOT NULL DEFAULT 'image',
  sort_index INTEGER NOT NULL DEFAULT 0
)`;

const CREATE_EXPENSES: string = `CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  trip_id TEXT NOT NULL DEFAULT '',
  amount REAL NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'other',
  note TEXT NOT NULL DEFAULT '',
  spent_at INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  sync_state INTEGER NOT NULL DEFAULT 1
)`;

const CREATE_CHECKLIST: string = `CREATE TABLE IF NOT EXISTS checklist (
  id TEXT PRIMARY KEY,
  trip_id TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  done INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0
)`;

const CREATE_FOOTPRINTS: string = `CREATE TABLE IF NOT EXISTS footprints (
  id TEXT PRIMARY KEY,
  trip_id TEXT NOT NULL DEFAULT '',
  place_name TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  latitude REAL NOT NULL DEFAULT 0,
  longitude REAL NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  visited_at INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0
)`;

const CREATE_PROFILE: string = `CREATE TABLE IF NOT EXISTS profile (
  id TEXT PRIMARY KEY,
  nickname TEXT NOT NULL DEFAULT '',
  avatar_uri TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL DEFAULT 0
)`;

const CREATE_META: string = `CREATE TABLE IF NOT EXISTS app_meta (
  meta_key TEXT PRIMARY KEY,
  meta_value TEXT NOT NULL DEFAULT ''
)`;

export class DatabaseHelper {
  private static store: relationalStore.RdbStore | undefined = undefined;
  private static opening: Promise<relationalStore.RdbStore> | undefined = undefined;

  static init(context: common.Context): void {
    if (DatabaseHelper.opening === undefined) {
      DatabaseHelper.opening = DatabaseHelper.open(context);
    }
  }

  static async getStore(): Promise<relationalStore.RdbStore> {
    if (DatabaseHelper.store !== undefined) {
      return DatabaseHelper.store;
    }
    if (DatabaseHelper.opening === undefined) {
      throw new Error('DatabaseHelper.init(context) must be called before accessing the database.');
    }
    return await DatabaseHelper.opening;
  }

  private static async open(context: common.Context): Promise<relationalStore.RdbStore> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    await store.execute(CREATE_TRIPS);
    await store.execute(CREATE_MEMBERS);
    await store.execute(CREATE_MOMENTS);
    await store.execute(CREATE_MOMENT_MEDIA);
    await store.execute(CREATE_EXPENSES);
    await store.execute(CREATE_CHECKLIST);
    await store.execute(CREATE_FOOTPRINTS);
    await store.execute(CREATE_PROFILE);
    await store.execute(CREATE_META);
    await DatabaseHelper.seedIfNeeded(store);
    DatabaseHelper.store = store;
    hilog.info(DOMAIN, TAG, 'database ready');
    return store;
  }

  private static async readMeta(store: relationalStore.RdbStore, key: string): Promise<string> {
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT meta_value FROM app_meta WHERE meta_key = ?', [key]);
    let value: string = '';
    if (rs.goToFirstRow()) {
      value = rs.getString(rs.getColumnIndex('meta_value'));
    }
    rs.close();
    return value;
  }

  /**
   * 首次启动播种一份示例旅程，避免空屏；用 app_meta 打标，删除数据后不会重复播种。
   */
  private static async seedIfNeeded(store: relationalStore.RdbStore): Promise<void> {
    const seeded: string = await DatabaseHelper.readMeta(store, 'seeded');
    if (seeded === '1') {
      return;
    }
    const now: number = Date.now();
    const dayMs: number = 24 * 60 * 60 * 1000;
    const start: number = now - 32 * dayMs;
    const tripId: string = 'demo-trip-hokkaido';
    const ownerId: string = 'demo-user-me';

    const profile: relationalStore.ValuesBucket = {
      'id': ownerId,
      'nickname': '我',
      'avatar_uri': '',
      'created_at': now
    };
    await store.insert('profile', profile, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

    const trip: relationalStore.ValuesBucket = {
      'id': tripId,
      'title': '北海道夏日之旅',
      'destination': '日本 · 北海道',
      'start_date': start,
      'end_date': start + 5 * dayMs,
      'note': '从札幌到函馆，一路看海、吃拉面。',
      'cover_uri': '',
      'owner_id': ownerId,
      'invite_code': 'HK2026',
      'created_at': now,
      'updated_at': now,
      'sync_state': 0
    };
    await store.insert('trips', trip, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

    const owner: relationalStore.ValuesBucket = {
      'id': 'demo-member-owner',
      'trip_id': tripId,
      'user_id': ownerId,
      'name': '我',
      'role': 'owner',
      'joined_at': now
    };
    await store.insert('members', owner, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    const companion: relationalStore.ValuesBucket = {
      'id': 'demo-member-2',
      'trip_id': tripId,
      'user_id': 'demo-user-2',
      'name': '小陈',
      'role': 'member',
      'joined_at': now
    };
    await store.insert('members', companion, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

    const moments: relationalStore.ValuesBucket[] = [
      {
        'id': 'demo-moment-1', 'trip_id': tripId, 'day_index': 1,
        'content': '抵达小樽，运河边的煤气灯一盏盏亮起来，风里有点凉。',
        'location_name': '小樽运河', 'latitude': 43.1993, 'longitude': 141.0024,
        'created_at': start, 'updated_at': start, 'sync_state': 0
      },
      {
        'id': 'demo-moment-2', 'trip_id': tripId, 'day_index': 2,
        'content': '函馆山的夜景真的值得等，缆车排队四十分钟也值。',
        'location_name': '函馆山', 'latitude': 41.7597, 'longitude': 140.7288,
        'created_at': start + dayMs, 'updated_at': start + dayMs, 'sync_state': 0
      },
      {
        'id': 'demo-moment-3', 'trip_id': tripId, 'day_index': 3,
        'content': '狸小路找了一家只有六个座位的小店，老板会一点中文。',
        'location_name': '狸小路商店街', 'latitude': 43.0554, 'longitude': 141.3535,
        'created_at': start + 2 * dayMs, 'updated_at': start + 2 * dayMs, 'sync_state': 0
      }
    ];
    for (const moment of moments) {
      await store.insert('moments', moment, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }

    const expenses: relationalStore.ValuesBucket[] = [
      {
        'id': 'demo-expense-1', 'trip_id': tripId, 'amount': 4200, 'category': 'food',
        'note': '海鲜烧烤', 'spent_at': start + dayMs, 'created_at': now, 'sync_state': 0
      },
      {
        'id': 'demo-expense-2', 'trip_id': tripId, 'amount': 1800, 'category': 'transport',
        'note': 'JR 特急', 'spent_at': start + 2 * dayMs, 'created_at': now, 'sync_state': 0
      },
      {
        'id': 'demo-expense-3', 'trip_id': tripId, 'amount': 6200, 'category': 'stay',
        'note': '温泉旅馆', 'spent_at': start + 2 * dayMs, 'created_at': now, 'sync_state': 0
      },
      {
        'id': 'demo-expense-4', 'trip_id': tripId, 'amount': 900, 'category': 'ticket',
        'note': '函馆山缆车', 'spent_at': start + dayMs, 'created_at': now, 'sync_state': 0
      }
    ];
    for (const expense of expenses) {
      await store.insert('expenses', expense, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }

    const checklist: relationalStore.ValuesBucket[] = [
      { 'id': 'demo-check-1', 'trip_id': tripId, 'title': '护照与证件', 'done': 1, 'created_at': now },
      { 'id': 'demo-check-2', 'trip_id': tripId, 'title': '转换插头', 'done': 0, 'created_at': now + 1 },
      { 'id': 'demo-check-3', 'trip_id': tripId, 'title': '防晒霜', 'done': 0, 'created_at': now + 2 }
    ];
    for (const item of checklist) {
      await store.insert('checklist', item, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }

    const footprints: relationalStore.ValuesBucket[] = [
      {
        'id': 'demo-foot-1', 'trip_id': tripId, 'place_name': '小樽运河', 'city': '小樽',
        'latitude': 43.1993, 'longitude': 141.0024, 'note': '傍晚最美',
        'visited_at': start, 'created_at': now
      },
      {
        'id': 'demo-foot-2', 'trip_id': tripId, 'place_name': '函馆山', 'city': '函馆',
        'latitude': 41.7597, 'longitude': 140.7288, 'note': '夜景',
        'visited_at': start + dayMs, 'created_at': now
      },
      {
        'id': 'demo-foot-3', 'trip_id': tripId, 'place_name': '狸小路', 'city': '札幌',
        'latitude': 43.0554, 'longitude': 141.3535, 'note': '',
        'visited_at': start + 2 * dayMs, 'created_at': now
      }
    ];
    for (const footprint of footprints) {
      await store.insert('footprints', footprint, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }

    const meta: relationalStore.ValuesBucket = { 'meta_key': 'seeded', 'meta_value': '1' };
    await store.insert('app_meta', meta, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    hilog.info(DOMAIN, TAG, 'demo data seeded');
  }
}