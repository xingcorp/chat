export function isOptional(value: any, defaultValue: any = null) {
    return value !== undefined ? value : defaultValue
}

export function castValueToDate(value: any) {
    return value && !(value instanceof Date) ? new Date(value) : value
}

export function calculateDistanceInKm(la1: number, lo1: number, la2: number, lo2: number) {
    const dLat = (la2 - la1) * (Math.PI / 180);
    const dLon = (lo2 - lo1) * (Math.PI / 180);
    const la1ToRad = la1 * (Math.PI / 180);
    const la2ToRad = la2 * (Math.PI / 180);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(la1ToRad) * Math.cos(la2ToRad) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return c * 6371;
}

export function getPrivateSshKey(key: string): string {
    return `-----BEGIN OPENSSH PRIVATE KEY-----\n${key}\n-----END OPENSSH PRIVATE KEY-----\n`
}

export function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

export function extractUserIdsInMessage(message: string): string[] {
    // Regex explanation:
    // \[@    matches literally '[@'
    // (.*?)  is a capturing group that matches any character (except line breaks) minimally
    // \]     matches the literal closing bracket
    const mentionRegex = /\[@(.*?)\]/g;
    const userIds = [];
    let match;

    while ((match = mentionRegex.exec(message)) !== null) {
        userIds.push(match[1]); // match[1] is the captured user_id
    }

    return userIds;
}

export function replaceUserIdsWithNamesInMessage(message: string, userMap: { [key: string]: string }): string {
    // Regex explanation:
    // \[@(.*?)\] matches mentions like [@12345]
    // (.*?) is a capturing group that takes the user_id
    return message.replace(/\[@(.*?)\]/g, (match, userId) => {
        // Lookup the username by userId in the userMap
        const username = userMap[userId] || userId;
        return `[@${username}]`;
    });
}