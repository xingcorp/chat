import { registerEnumType } from "@nestjs/graphql"

export const WIKI_NOT_PUBLIC_VERSION = 'Chưa phát hành'
export enum DayOfWeek {
    Mon = 'Mon',
    Tue = 'Tue',
    Wed = 'Wed',
    Thu = 'Thu',
    Fri = 'Fri',
    Sat = 'Sat',
    Sun = 'Sun'
}
registerEnumType(DayOfWeek, { name: 'DayOfWeek' })
