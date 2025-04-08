import * as dotenv from 'dotenv';
dotenv.config();

import * as moment from "moment/moment";
import { DateFormater } from "@common/date.formater";
import { DayOfWeek } from '@common/constant.common';

export enum SECONDS_TIMESTAMP {
    '1H' = 60 * 60
}

export enum TIMESTAMP {
    '15m' = 15 * 60 * 1000,
    '1H' = 60 * 60 * 1000,
    '1D' = 24 * 60 * 60 * 1000,
    '7D' = 7 * 24 * 60 * 60 * 1000,
    '1Y' = 365 * 24 * 60 * 60 * 1000,
}

export const DayOfWeekOrder = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

export const countMonthFromDateToNow = (date: Date | null, defaultVal: any = '-') => {
    if (!date) return defaultVal;

    const now = new Date()
    let months = (now.getFullYear() - date.getFullYear()) * 12;
    months -= date.getMonth();
    months += now.getMonth();
    return months <= 0 ? 0 : months;
}

export const countMonthBetweenTwoDate = (start: Date, end: Date, defaultVal: any = '-') => {
    if (!start) return defaultVal;
    if (!end) end = new Date()

    let months = (end.getFullYear() - start.getFullYear()) * 12;
    months -= start.getMonth();
    months += end.getMonth();
    return months <= 0 ? 0 : months;
}

export const countYearBetweenTwoDate = (start: Date, end: Date) => {
    if (!start || !end) return '-'
    return end.getFullYear() - start.getFullYear()
}

export const dayMonthYearToTime = (stringDate: string) => {
    let arr1 = stringDate.split("-");
    let arr2 = stringDate.split("/");
    const arr = arr1.length === 3 ? arr1 : arr2

    const newDate = new Date(parseInt(arr[2]), parseInt(arr[1]) - 1, parseInt(arr[0]));

    return newDate.getTime()
}

export const datetimeGetFormat = (format: string = 'DD/MM/YYYY HH:mm:ss', value?: number | string | Date) =>
    (moment(value ? new Date(value) : new Date())).format(format)

export const datetimeGetDateFromFormat = (format: string = 'DD/MM/YYYY HH:mm:ss', value?: number | string | Date) =>
    value ? DateFormater.stringToDateWithFormat(value, format) : null

export const datetimeGetDateLocalFromFormat = (format: string = 'DD/MM/YYYY HH:mm:ss', value?: number | string | Date) =>
    value ? DateFormater.stringToDateLocalWithFormat(value, format) : null

export const datetimeGetTimestampLocalFromFormat = (value?: number | string | Date) =>
    value ? DateFormater.getTimestampLocalWithFormat(value) : null

export function datetimeOfLocalDay(value?: number | string | Date) {
    return DateFormater.dateOfLocalDay(value ? new Date(value) : new Date())
}

export function datetimeOfLocalDayToString(format: string, value?: number | string | Date) {
    return DateFormater.dateOfLocalDayToString(value ? new Date(value) : new Date(), format)
}

export function datetimeStartOfLocalDay(value?: number | string | Date) {
    return DateFormater.startOfLocalDay(value ? new Date(value) : new Date())
}

export function datetimeEndOfLocalDay(value?: number | string | Date) {
    return DateFormater.endOfLocalDay(value ? new Date(value) : new Date())
}

export function getDateLocal(date: Date = new Date()) {
    return new Date(
        date.getTime()
        - date.getTimezoneOffset() * 60 * 1000
        + ((-process.env.TIMEZONE_NUMBER) * 60) * 60 * 1000
    )
}

export function getTimeLocal(date: Date = new Date()) {
    return getDateLocal(date).getTime()
}

export function transformDDMMYYYFullCharacter(str: string | null, slash: string = '/'): string {
    if (!str || !str.includes(slash)) return str

    const [day, month, year] = str.split(slash);
    const fullDay = day?.length === 1 ? `0${day}` : day
    const fullMonth = month?.length === 1 ? `0${month}` : month

    return [fullDay, fullMonth, year].join(slash)
}

export function getDateByTimestamp(str: number) {
    return str ? new Date(str) : null
}

export function getDateFutureMonthByDate(date: Date | number | string, month: number) {
    return date ? DateFormater.futureMonths(new Date(date), month) : null
}

export function datetimeStartTimeInMinutesGet(date: Date | number | string, timezone: number = 7) {
    const datetime = new Date(date)
    return ((datetime.getHours() + (timezone ?? 0)) % 24) * 60 + datetime.getMinutes()
}

export function datetimeGetDayOfWeekTitle(date: Date | number | string) {
    const datetime = new Date(date)

    return DayOfWeekOrder[datetime.getDay()]
}

export function datetimeGetDayOfWeekTitleShort(date: Date | number | string, length: number = 3) {
    return datetimeGetDayOfWeekTitle(date).substring(0, length)
}

export function datetimeDateRoundToHourGet(date: Date | number | string) {
    const res = new Date(date)
    res.setMinutes(0)
    res.setSeconds(0)
    res.setMilliseconds(0)

    return res
}

export function datetimeDateRoundToMinuteGet(date: Date | number | string) {
    const res = new Date(date)
    res.setSeconds(0)
    res.setMilliseconds(0)

    return res
}

export function datetimeDateEndOfToMinuteGet(date: Date | number | string) {
    const res = new Date(date)
    res.setSeconds(59)
    res.setMilliseconds(999)

    return res
}

export function datetimeGetNextDateByHours(date: Date | number | string, nextHours: number) {
    return new Date((new Date(date)).getTime() + nextHours * 60 * 60 * 1000)
}

export function datetimeGetNextDateByDays(date: Date | number | string, nextDays: number) {
    return datetimeGetNextDateByHours(date, nextDays * 24)
}

export function datetimeSetTime(date: Date | number | string, hour: number = 0, minute: number = 0, second: number = 0) {
    const res = new Date(date)
    res.setHours(hour, minute, second, 0)

    return res
}

export function datetimeAddTime(date: Date | number | string, hour: number = 0, minute: number = 0, second: number = 0) {
    const res = new Date(date)

    return new Date(res.getTime() + 1000 * (hour * 60 * 24 + minute * 60 + second))
}

export function datetimeAddTimestamp(date: Date | number | string, timestamp: number = 0) {
    const res = new Date(date)

    return new Date(res.getTime() + timestamp)
}

export function datetimeLocalGetDay(value?: number | string | Date) {
    return DateFormater.localGetDay(value ? new Date(value) : new Date())
}

export function datetimeLocalGetDate(value?: number | string | Date) {
    return DateFormater.localGetDate(value ? new Date(value) : new Date())
}

export function getWeekDayNumber(weekDays: DayOfWeek[]): number[] {
    if (!weekDays) {
        return []
    }

    return weekDays.map(w => {
        if (w === DayOfWeek.Sun) {
            return 0
        } else if (w === DayOfWeek.Mon) {
            return 1
        } else if (w === DayOfWeek.Tue) {
            return 2
        } else if (w === DayOfWeek.Wed) {
            return 3
        } else if (w === DayOfWeek.Thu) {
            return 4
        } else if (w === DayOfWeek.Fri) {
            return 5
        } else if (w === DayOfWeek.Sat) {
            return 6
        }
    })
}

export function combineDateAndTime(date: Date, time: Date): Date {
    const datePart = new Date(date);
    const timePart = new Date(time);

    return new Date(
        datePart.getFullYear(),
        datePart.getMonth(),
        datePart.getDate(),
        timePart.getHours(),
        timePart.getMinutes(),
        timePart.getSeconds()
    );
}