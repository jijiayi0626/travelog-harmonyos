import { Expense, EXPENSE_CATEGORIES } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { categoryColor } from '../utils/CategoryUtil';

@ObservedV2
export class CategoryStat {
  public category: string = '';
  public amount: number = 0;
  public count: number = 0;
  public ratio: number = 0;
  public color: string = '#6B7280';
}

@ObservedV2
export class ExpenseViewModel {
  @Trace public expenses: Expense[] = [];
  @Trace public loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();

  async loadAll(): Promise<void> {
    this.loading = true;
    try {
      this.expenses = await this.repository.listAllExpenses();
    } finally {
      this.loading = false;
    }
  }

  async loadByTrip(tripId: string): Promise<void> {
    this.loading = true;
    try {
      this.expenses = await this.repository.listExpenses(tripId);
    } finally {
      this.loading = false;
    }
  }

  @Computed
  get total(): number {
    let total: number = 0;
    for (const expense of this.expenses) {
      total += expense.amount;
    }
    return total;
  }

  @Computed
  get categoryStats(): CategoryStat[] {
    const stats: CategoryStat[] = [];
    for (const category of EXPENSE_CATEGORIES) {
      const stat: CategoryStat = new CategoryStat();
      stat.category = category;
      stat.color = categoryColor(category);
      stats.push(stat);
    }
    for (const expense of this.expenses) {
      for (const stat of stats) {
        if (stat.category === expense.category) {
          stat.amount += expense.amount;
          stat.count++;
          break;
        }
      }
    }
    const max: number = this.maxCategoryAmount(stats);
    for (const stat of stats) {
      stat.ratio = max > 0 ? stat.amount / max : 0;
    }
    return stats;
  }

  private maxCategoryAmount(stats: CategoryStat[]): number {
    let max: number = 0;
    for (const stat of stats) {
      if (stat.amount > max) {
        max = stat.amount;
      }
    }
    return max;
  }
}