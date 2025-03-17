import * as moment from 'moment'

export class DateFormater {
    static timestampToString = (value: number) => {
        return (moment(new Date(value))).format('DD/MM/YYYY HH:mm:ss')
    }

    static timestampToStringWithFormat = (value: number, format: string) => {
        return (moment(new Date(value))).format(format)
    }

    static dateStringToString = (value: string) => {
        if (!value || value.length === 0) return ''
        return (moment(new Date(value))).format('DD/MM/YYYY HH:mm:ss')
    }

    static dateStringToStringWithFormat = (value: string, format: string) => {
        if (!value || value.length === 0) return ''
        return (moment(new Date(value))).format(format)
    }

    static dateToString = (value: Date) => {
        return (moment(value)).format('DD/MM/YYYY HH:mm:ss')
    }

    static dateToStringWithFormat = (value: Date, format: string) => {
        return (moment(value)).format(format)
    }

    static stringToDate = (value: string) => {
        return moment(value, 'DD/MM/YYYY HH:mm:ss').toDate()
    }

    static stringToDateWithFormat = (value: number | string | Date, format: string) => {
        return moment(value, format).toDate()
    }

    static formaterDateToStringWithFormat = (value: Date, format: string) => {
        return (moment(value)).format(format)
    }

    static getTimestampLocalWithFormat(value: number | string | Date) {
        return (moment(value).unix() - 7 * 60 * 60) * 1000
    }

    static stringToDateLocalWithFormat(value: number | string | Date, format: string) {
        return moment(value, format).utcOffset('+0700').toDate()
    }

    static dateOfLocalDay = (value: Date) => {
        return (moment(value)).utcOffset('+0700').toDate()
    }

    static dateOfLocalDayToString = (value: Date, format: string) => {
        return (moment(value)).utcOffset('+0700').format(format)
    }

    static startOfLocalDay = (value: Date) => {
        return (moment(value)).utcOffset('+0700').startOf('day').toDate()
    }

    static endOfLocalDay = (value: Date) => {
        return (moment(value)).utcOffset('+0700').endOf('day').toDate()
    }

    static futureMonths = (date: Date, month: number) => {
        return moment(date).add(month, 'month').toDate()
    }

    static localGetDay(value: Date) {
        return (moment(value)).utcOffset('+0700').day()
    }

    static localGetDate(value: Date) {
        return (moment(value)).utcOffset('+0700').date()
    }
}
