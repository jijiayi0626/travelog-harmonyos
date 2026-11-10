/**
 * 轻提示统一入口，避免各页面重复拼 promptAction 调用。
 */
export function showToast(uiContext: UIContext, message: Resource | string): void {
  try {
    uiContext.getPromptAction().showToast({
      message: message,
      duration: 2000
    });
  } catch (err) {
    // 忽略提示失败，不影响主流程
  }
}