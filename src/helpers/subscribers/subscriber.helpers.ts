import { BaseEntity, UpdateEvent } from "typeorm";

export class SubscriberHelpers {
    static isChangeField(event: UpdateEvent<BaseEntity>, fieldName: string) {
        const fieldsChange = [...new Set([
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ])]

        return fieldsChange.includes(fieldName)
    }
}