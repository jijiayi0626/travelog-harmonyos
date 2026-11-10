import { Footprint } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';

@ObservedV2
export class FootprintViewModel {
  @Trace public footprints: Footprint[] = [];
  @Trace public loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.footprints = await this.repository.listFootprints();
    } finally {
      this.loading = false;
    }
  }

  @Computed
  get cityCount(): number {
    const cities: string[] = [];
    for (const item of this.footprints) {
      if (item.city !== '' && cities.indexOf(item.city) < 0) {
        cities.push(item.city);
      }
    }
    return cities.length;
  }
}