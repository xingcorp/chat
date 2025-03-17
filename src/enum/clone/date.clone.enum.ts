import { registerEnumType } from "@nestjs/graphql";

export enum CloneDatePeriodEnum {
    Now = 'Now',
    Daily = 'Daily',
    Weekly = 'Weekly',
    Monthly = 'Monthly',
    Custom = 'Custom',
}
registerEnumType(CloneDatePeriodEnum, { name: 'CloneDatePeriodEnum' })


export enum CloneDatePeriodTitleEnum {
    Now = 'Ngay bây giờ',
    Daily = 'Hàng ngày',
    Weekly = 'Hàng tuần',
    Monthly = 'Hàng tháng',
    Custom = 'Định kỳ'
}

export enum CloneDateTypeEnum {
    TaskReportConfig = 'TaskReportConfig',
    BookingMeetingRoom = 'BookingMeetingRoom',
}