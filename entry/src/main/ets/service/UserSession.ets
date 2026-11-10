/**
 * 当前登录用户。通过 AppStorageV2 在页面间共享：
 *   @Local session: UserSession = AppStorageV2.connect(UserSession, 'UserSession', () => new UserSession())!;
 * 本地模式下 accountType 恒为 'local'；接入云端后改成 'cloud' 并填入服务端 userId。
 */
@ObservedV2
export class UserSession {
  @Trace public userId: string = '';
  @Trace public nickname: string = '';
  @Trace public avatarUri: string = '';
  @Trace public accountType: string = 'local';

  get isLocal(): boolean {
    return this.accountType === 'local';
  }
}