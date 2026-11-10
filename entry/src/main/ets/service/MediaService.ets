import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0001;
const TAG: string = 'MediaService';

/**
 * 相册选图并复制到应用沙箱，返回可直接给 Image 使用的 file:// 路径。
 * 复制而非直接存 picker URI，避免授权 URI 在重启后失效。
 */
export class MediaService {
  static async pickAndPersist(context: common.Context, maxCount: number): Promise<string[]> {
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxCount;
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);

    const dir: string = context.filesDir + '/moment_images';
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir);
    }
    const saved: string[] = [];
    const stamp: number = Date.now();
    for (let i = 0; i < result.photoUris.length; i++) {
      try {
        const source: fs.File = fs.openSync(result.photoUris[i], fs.OpenMode.READ_ONLY);
        const target: string = dir + '/img_' + stamp + '_' + i + '.jpg';
        fs.copyFileSync(source.fd, target);
        fs.closeSync(source);
        saved.push('file://' + target);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'copy image failed: %{public}s', JSON.stringify(err));
      }
    }
    return saved;
  }

  /** 删除已保存的沙箱图片，用于记录删除时清理 */
  static removeQuietly(fileUri: string): void {
    if (fileUri.startsWith('file://')) {
      try {
        fs.unlinkSync(fileUri.substring('file://'.length));
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'remove image failed');
      }
    }
  }
}