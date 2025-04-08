import * as IdentifyCardPlaceData from "@modules/graphql/master-data/data/identify-card-place.json";

export function identifyCardPlaceListValue() {
    return identifyCardPlaceListSort().map(i => i.name)
}

export function identifyCardPlaceListSort() {
    return Object.values(IdentifyCardPlaceData).sort((a, b) => {
        if (a.type === b.type) return a.name < b.name ? -1 : 1
        const ordinal = {
            'tw': 0,
            'thanh-pho': 1,
            'tinh': 2,
        }
        return ordinal[a.type] - ordinal[b.type]
    })
}