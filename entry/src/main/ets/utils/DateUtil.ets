import { TripStatus } from '../model/Entities';

const DAY_MS: number = 24 * 60 * 60 * 1000;

export function pad2(value: number): string {
  return value < 10 ? '0' + value : '' + value;
}

/** 2026.08.12 */
export function formatDate(timestamp: number): string {
  if (timestamp <= 0) {
    return '';
  }
  const date: Date = new Date(timestamp);
  return date.getFullYear() + '.' + pad2(date.getMonth() + 1) + '.' + pad2(date.getDate());
}

/** 8月12日 */
export function formatDateCn(timestamp: number): string {
  if (timestamp <= 0) {
    return '';
  }
  const date: Date = new Date(timestamp);
  return (date.getMonth() + 1) + '月' + date.getDate() + '日';
}

/** 12:05 */
export function formatTime(timestamp: number): string {
  const date: Date = new Date(timestamp);
  return pad2(date.getHours()) + ':' + pad2(date.getMinutes());
}

/** 千分位金额，保留两位小数 */
export function formatMoney(amount: number): string {
  const fixed: string = Math.abs(amount).toFixed(2);
  const parts: string[] = fixed.split('.');
  let integerPart: string = parts[0];
  let result: string = '';
  let count: number = 0;
  for (let i = integerPart.length - 1; i >= 0; i--) {
    result = integerPart.charAt(i) + result;
    count++;
    if (count % 3 === 0 && i > 0) {
      result = ',' + result;
    }
  }
  const prefix: string = amount < 0 ? '-' : '';
  return prefix + result + '.' + parts[1];
}

/** 行程天数，含首尾 */
export function tripDayCount(startDate: number, endDate: number): number {
  if (startDate <= 0 || endDate <= 0 || endDate < startDate) {
    return 0;
  }
  return Math.floor((endDate - startDate) / DAY_MS) + 1;
}

/** 记录属于行程第几天（从 1 开始），超出范围返回 0 */
export function dayIndexInTrip(startDate: number, timestamp: number): number {
  if (startDate <= 0 || timestamp < startDate) {
    return 0;
  }
  return Math.floor((timestamp - startDate) / DAY_MS) + 1;
}

export function tripStatusOf(startDate: number, endDate: number): TripStatus {
  const now: number = Date.now();
  if (startDate <= 0 || endDate <= 0) {
    return TripStatus.PLANNED;
  }
  if (now < startDate) {
    return TripStatus.PLANNED;
  }
  if (now > endDate + DAY_MS) {
    return TripStatus.FINISHED;
  }
  return TripStatus.ONGOING;
}

/** 当天 00:00 的时间戳，用于日期选择器归一化 */
export function startOfDay(timestamp: number): number {
  const date: Date = new Date(timestamp);
  date.setHours(0, 0, 0, 0);
  return date.getTime();
}

export function todayStart(): number {
  return startOfDay(Date.now());
}

export function withDayOffset(base: number, offsetDays: number): number {
  return base + offsetDays * DAY_MS;
}