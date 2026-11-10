import { Trip } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';

@ObservedV2
export class TripListViewModel {
  @Trace public trips: Trip[] = [];
  @Trace public loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.trips = await this.repository.listTrips();
    } finally {
      this.loading = false;
    }
  }
}