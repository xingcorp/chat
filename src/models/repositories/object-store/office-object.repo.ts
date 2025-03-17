import { Injectable } from "@nestjs/common";
import { DataSource, In, IsNull, Repository } from "typeorm";
import { OfficeObject } from "@models/entities/object-store/office-object";
import { OfficeObjectType } from "@enum/object-store/object-store.enum";

@Injectable()
export class OfficeObjectRepo extends Repository<OfficeObject> {
    constructor(private dataSource: DataSource) {
        super(OfficeObject, dataSource.createEntityManager());
    }

    async storeData(officeStoreData: OfficeObject) {
        const record = this.create(officeStoreData)

        return this.save(record)
    }

    async updateManyRelation(ids: string[], id: string, type: OfficeObjectType = null) {
        const objects = await this.find({
            where: {
                id: In(ids),
                relationId: IsNull()
            }
        })

        objects.map(i => i.relationId = id)

        if (type) {
            objects.map(i => i.relationType = type)
        }

        return this.save(objects)
    }

    async removeManyRelation(id: string, type: OfficeObjectType) {
        return this.createQueryBuilder()
            .update()
            .set({ relationId: null })
            .where({
                relationId: id,
                relationType: type
            })
            .execute();
    }
}