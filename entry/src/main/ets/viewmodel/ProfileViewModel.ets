import { AppStats } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';

@ObservedV2
export class ProfileViewModel {
  @Trace public stats: AppStats = new AppStats();
  @Trace public loading: boolean = true;

  private repository: ITravelRepository = RepositoryProvider.get();

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.stats = await this.repository.stats();
    } finally {
      this.loading = false;
    }
  }
}