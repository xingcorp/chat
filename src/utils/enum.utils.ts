export enum DayOfTheWeek {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
}

export enum DayOfTheWeekTitle {
    Sunday = 'Sunday',
    Monday = 'Monday',
    Tuesday = 'Tuesday',
    Wednesday = 'Wednesday',
    Thursday = 'Thursday',
    Friday = 'Friday',
    Saturday = 'Saturday',
}

export enum GrantType {
    User='User',
    Department='Department',
}

export enum PeriodDate {
    User='User',
    Department='Department',
}

export const enumTextGetKeys = (Enum: any) => Object.keys(Enum).filter(key => Enum[key])
export const enumTextGetVals = (Enum: any) => {
    const keys = enumTextGetKeys(Enum)
    const res = []
    keys.map(i => res.push(Enum[i]))

    return res
}

export const enumGetKey = (Enum: any, val: any) => Object.keys(Enum)[Object.values(Enum).indexOf(val)];
