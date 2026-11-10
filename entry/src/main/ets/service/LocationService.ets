import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0001;
const TAG: string = 'LocationService';

export class Coordinate {
  public latitude: number = 0;
  public longitude: number = 0;
}

export class LocationService {
  static async requestPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const permissions: Array<Permissions> = [
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ];
      const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const result: abilityAccessCtrl.PermissionRequestResult =
        await manager.requestPermissionsFromUser(context, permissions);
      for (const code of result.authResults) {
        if (code !== 0) {
          return false;
        }
      }
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'request permission failed');
      return false;
    }
  }

  /** 获取单次定位；失败返回 undefined，UI 回退到手动填写。 */
  static async getCurrent(): Promise<Coordinate | undefined> {
    try {
      const request: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        timeoutMs: 8000
      };
      const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation(request);
      const coordinate: Coordinate = new Coordinate();
      coordinate.latitude = location.latitude;
      coordinate.longitude = location.longitude;
      return coordinate;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'get current location failed');
      return undefined;
    }
  }
}