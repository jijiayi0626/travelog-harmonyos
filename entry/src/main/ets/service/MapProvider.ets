import { common, Want } from '@kit.AbilityKit';

/**
 * 地图能力抽象层。
 *
 * 现状：调用系统地图展示单个坐标（geo: scheme），不依赖 AGC 地图服务，开箱可用。
 * 升级路径（应用内嵌地图）：在 AGC 开通 Map Kit 并配置 client_id 后，
 * 使用 @kit.MapKit 的 MapComponent 替换 FootprintTab 中的列表区块，
 * 本类仅保留「外部跳转」职责即可，页面无需改动数据结构。
 */
export class MapPoint {
  public latitude: number = 0;
  public longitude: number = 0;
  public title: string = '';
}

export class SystemMapLauncher {
  static async open(context: common.UIAbilityContext, latitude: number, longitude: number,
    name: string): Promise<void> {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: 'geo:' + latitude + ',' + longitude + '?q=' + encodeURIComponent(name)
    };
    await context.startAbility(want);
  }
}