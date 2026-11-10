import { ITravelRepository } from './ITravelRepository';
import { RdbTravelRepository } from './RdbTravelRepository';

/**
 * 数据访问层唯一的注入点。
 * 接入云端时：实现 RemoteTravelRepository，并调用 RepositoryProvider.use(new RemoteTravelRepository())。
 */
export class RepositoryProvider {
  private static repository: ITravelRepository = new RdbTravelRepository();

  static get(): ITravelRepository {
    return RepositoryProvider.repository;
  }

  static use(repository: ITravelRepository): void {
    RepositoryProvider.repository = repository;
  }
}