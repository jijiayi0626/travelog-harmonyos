import { AppStorageV2 } from '@kit.ArkUI';
import { TripEditParam, AppRouter } from '../common/Routes';
import { Trip } from '../model/Entities';
import { ITravelRepository } from '../data/ITravelRepository';
import { RepositoryProvider } from '../data/RepositoryProvider';
import { AppRefresh } from '../service/AppRefresh';
import { UserSession } from '../service/UserSession';
import { formatDate, startOfDay } from '../utils/DateUtil';
import { showToast } from '../common/ToastUtil';

@ComponentV2
export struct TripEditPage {
  @Param param: TripEditParam = { tripId: '' };
  @Local title: string = '';
  @Local destination: string = '';
  @Local note: string = '';
  @Local startDate: number = 0;
  @Local endDate: number = 0;
  @Local loading: boolean = true;
  @Local saving: boolean = false;
  @Local refresh: AppRefresh = AppStorageV2.connect(AppRefresh, 'AppRefresh', () => new AppRefresh())!;
  @Local session: UserSession = AppStorageV2.connect(UserSession, 'UserSession', () => new UserSession())!;

  private repository: ITravelRepository = RepositoryProvider.get();
  private trip: Trip = new Trip();

  async aboutToAppear(): Promise<void> {
    if (this.param.tripId !== '') {
      const existing: Trip | undefined = await this.repository.getTrip(this.param.tripId);
      if (existing !== undefined) {
        this.trip = existing;
        this.title = existing.title;
        this.destination = existing.destination;
        this.note = existing.note;
        this.startDate = existing.startDate;
        this.endDate = existing.endDate;
      }
    }
    this.loading = false;
  }

  private pickStartDate(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: new Date(this.startDate > 0 ? this.startDate : Date.now()),
      onDateAccept: (value: Date) => {
        this.startDate = startOfDay(value.getTime());
        if (this.endDate < this.startDate) {
          this.endDate = this.startDate;
        }
      }
    });
  }

  private pickEndDate(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: new Date(this.endDate > 0 ? this.endDate : (this.startDate > 0 ? this.startDate : Date.now())),
      onDateAccept: (value: Date) => {
        this.endDate = startOfDay(value.getTime());
        if (this.startDate === 0) {
          this.startDate = this.endDate;
        }
      }
    });
  }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    if (this.title.trim() === '') {
      showToast(this.getUIContext(), $r('app.string.toast_required'));
      return;
    }
    this.saving = true;
    this.trip.title = this.title.trim();
    this.trip.destination = this.destination.trim();
    this.trip.note = this.note;
    this.trip.startDate = this.startDate;
    this.trip.endDate = this.endDate;
    if (this.trip.ownerId === '') {
      this.trip.ownerId = this.session.userId;
    }
    await this.repository.saveTrip(this.trip);
    this.refresh.bump();
    this.saving = false;
    showToast(this.getUIContext(), $r('app.string.toast_saved'));
    AppRouter.pop();
  }

  @Builder
  FieldLabel(label: Resource) {
    Text(label)
      .fontSize(12)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
  }

  @Builder
  DateField(label: Resource, timestamp: number, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
      Blank()
      Text(timestamp > 0 ? formatDate(timestamp) : ($r('app.string.trip_no_date') as ResourceStr))
        .fontSize(14)
        .fontColor(timestamp > 0 ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
      Text('  ›')
        .fontSize(14)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .height(44)
    .onClick(onTap)
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.primary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              this.FieldLabel($r('app.string.trip_title_label'))
              TextInput({ placeholder: $r('app.string.trip_title_placeholder'), text: this.title })
                .height(44)
                .fontSize(15)
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(12)
                .onChange((value: string) => {
                  this.title = value;
                })

              this.FieldLabel($r('app.string.trip_destination_label'))
              TextInput({ placeholder: $r('app.string.trip_destination_placeholder'), text: this.destination })
                .height(44)
                .fontSize(15)
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(12)
                .onChange((value: string) => {
                  this.destination = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)

            Column() {
              this.DateField($r('app.string.trip_start_date'), this.startDate, () => this.pickStartDate())
              Divider().strokeWidth(0.5).color($r('app.color.divider'))
              this.DateField($r('app.string.trip_end_date'), this.endDate, () => this.pickEndDate())
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(18)

            Column({ space: 10 }) {
              this.FieldLabel($r('app.string.trip_note_label'))
              TextArea({ placeholder: $r('app.string.trip_note_placeholder'), text: this.note })
                .height(110)
                .fontSize(14)
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(12)
                .onChange((value: string) => {
                  this.note = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)

            Button($r('app.string.action_save'))
              .width('100%')
              .height(46)
              .fontSize(15)
              .borderRadius(23)
              .backgroundColor($r('app.color.primary'))
              .enabled(!this.saving)
              .onClick(() => this.save())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title(this.param.tripId === '' ? $r('app.string.trip_create_title') : $r('app.string.trip_edit_title'))
    .backgroundColor($r('app.color.page_bg'))
  }
}