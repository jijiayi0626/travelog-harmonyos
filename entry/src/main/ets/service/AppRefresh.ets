/**
 * 跨页面刷新信号。任何写操作成功后 bump 一次，列表页通过 @Monitor 监听 tick 重新拉取。
 * 相比手动回传回调，能在 Navigation 任意层级返回时保持数据一致。
 */
@ObservedV2
export class AppRefresh {
  @Trace public tick: number = 0;

  bump(): void {
    this.tick++;
  }
}