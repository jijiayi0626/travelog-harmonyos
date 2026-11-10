import { AppStorageV2 } from '@kit.ArkUI';
import { ChecklistParam } from '../common/Routes';
import { ChecklistItem } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { ChecklistRow } from '../components/ChecklistRow';
import { EmptyState } from '../components/EmptyState';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct ChecklistPage {
  @Param param: ChecklistParam = { tripId: '' };
  @Local items: ChecklistItem[] = [];
  @Local newTitle: string = '';
  @Local loading: boolean = true;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;

  private repository: ITravelRepository = RepositoryProvider.get();

  async aboutToAppear(): Promise<void> {
    await this.load();
  }

  @Monitor('refresh.tick')
  onGlobalRefresh(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.items = await this.repository.listChecklist(this.param.tripId);
    this.loading = false;
  }

  private async add(): Promise<void> {
    const title: string = this.newTitle.trim();
    if (title === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    const item: ChecklistItem = new ChecklistItem();
    item.tripId = this.param.tripId;
    item.title = title;
    await this.repository.saveChecklistItem(item);
    this.newTitle = '';
    this.refresh.bump();
  }

  private async toggle(item: ChecklistItem, done: boolean): Promise<void> {
    item.done = done;
    await this.repository.saveChecklistItem(item);
    this.refresh.bump();
  }

  private async remove(item: ChecklistItem): Promise<void> {
    await this.repository.deleteChecklistItem(item.id);
    this.refresh.bump();
  }

  private doneCount(): number {
    let done: number = 0;
    for (const item of this.items) {
      if (item.done) {
        done++;
      }
    }
    return done;
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          TextInput({ placeholder: $r('app.string.checklist_add_placeholder'), text: this.newTitle })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)
            .onChange((value: string) => {
              this.newTitle = value;
            })
          Button($r('app.string.action_add'))
            .height(40)
            .fontSize(13)
            .borderRadius(20)
            .backgroundColor($r('app.color.primary'))
            .onClick(() => this.add())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10 })

        Text($r('app.string.checklist_progress_format', this.doneCount(), this.items.length))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16 })

        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color($r('app.color.primary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.items.length === 0) {
          EmptyState({
            icon: '🧳',
            title: $r('app.string.empty_checklist'),
            hint: $r('app.string.checklist_tip')
          })
        } else {
          List({ space: 8 }) {
            ForEach(this.items, (item: ChecklistItem) => {
              ListItem() {
                ChecklistRow({
                  item: item,
                  onToggle: (done: boolean) => this.toggle(item, done),
                  onDelete: () => this.remove(item)
                })
              }
            }, (item: ChecklistItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, bottom: 16 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))
    }
    .title($r('app.string.checklist_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}