import { ExpenseCategory, TripStatus } from '../model/Entities';

export function categoryLabel(category: string): Resource {
  switch (category) {
    case ExpenseCategory.FOOD:
      return $r('app.string.category_food');
    case ExpenseCategory.TRANSPORT:
      return $r('app.string.category_transport');
    case ExpenseCategory.STAY:
      return $r('app.string.category_stay');
    case ExpenseCategory.TICKET:
      return $r('app.string.category_ticket');
    case ExpenseCategory.SHOPPING:
      return $r('app.string.category_shopping');
    default:
      return $r('app.string.category_other');
  }
}

export function categoryIcon(category: string): string {
  switch (category) {
    case ExpenseCategory.FOOD:
      return '🍜';
    case ExpenseCategory.TRANSPORT:
      return '🚄';
    case ExpenseCategory.STAY:
      return '🏨';
    case ExpenseCategory.TICKET:
      return '🎫';
    case ExpenseCategory.SHOPPING:
      return '🛍️';
    default:
      return '🧾';
  }
}

export function categoryColor(category: string): string {
  switch (category) {
    case ExpenseCategory.FOOD:
      return '#F97316';
    case ExpenseCategory.TRANSPORT:
      return '#3B82F6';
    case ExpenseCategory.STAY:
      return '#8B5CF6';
    case ExpenseCategory.TICKET:
      return '#10B981';
    case ExpenseCategory.SHOPPING:
      return '#EC4899';
    default:
      return '#6B7280';
  }
}

export function tripStatusLabel(status: TripStatus): Resource {
  switch (status) {
    case TripStatus.ONGOING:
      return $r('app.string.trip_status_ongoing');
    case TripStatus.FINISHED:
      return $r('app.string.trip_status_finished');
    default:
      return $r('app.string.trip_status_planned');
  }
}

export function tripStatusColor(status: TripStatus): string {
  switch (status) {
    case TripStatus.ONGOING:
      return '#10B981';
    case TripStatus.FINISHED:
      return '#9CA3AF';
    default:
      return '#2563EB';
  }
}