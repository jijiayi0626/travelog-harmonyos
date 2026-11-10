import { ChecklistItem, Expense, Moment, Trip, TripMember } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';

@ObservedV2
export class MomentGroup {
  public dayIndex: number = 0;
  public moments: Moment[] = [];
}

@ObservedV2
export class TripDetailViewModel {
  @Trace public trip: Trip | undefined = undefined;
  @Trace public moments: Moment[] = [];
  @Trace public expenses: Expense[] = [];
  @Trace public checklist: ChecklistItem[] = [];
  @Trace public members: TripMember[] = [];
  @Trace public loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();

  async load(tripId: string): Promise<void> {
    this.loading = true;
    try {
      this.trip = await this.repository.getTrip(tripId);
      this.moments = await this.repository.listMoments(tripId);
      this.expenses = await this.repository.listExpenses(tripId);
      this.checklist = await this.repository.listChecklist(tripId);
      this.members = await this.repository.listMembers(tripId);
    } finally {
      this.loading = false;
    }
  }

  @Computed
  get totalExpense(): number {
    let total: number = 0;
    for (const expense of this.expenses) {
      total += expense.amount;
    }
    return total;
  }

  @Computed
  get checklistDone(): number {
    let done: number = 0;
    for (const item of this.checklist) {
      if (item.done) {
        done++;
      }
    }
    return done;
  }

  @Computed
  get groupedMoments(): MomentGroup[] {
    const groups: MomentGroup[] = [];
    for (const moment of this.moments) {
      let group: MomentGroup | undefined = undefined;
      for (const existing of groups) {
        if (existing.dayIndex === moment.dayIndex) {
          group = existing;
          break;
        }
      }
      if (group === undefined) {
        group = new MomentGroup();
        group.dayIndex = moment.dayIndex;
        groups.push(group);
      }
      group.moments.push(moment);
    }
    return groups;
  }
}