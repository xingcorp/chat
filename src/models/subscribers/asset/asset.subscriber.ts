import { Injectable } from "@nestjs/common";
import { Connection, EntityManager, EntitySubscriberInterface, InsertEvent, IsNull, Not } from "typeorm";
import { Asset, UserWorkProfileDetail } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { AssetRepo, OfficeUserRepo } from "@models/repositories";
import { stringNumberWithZeroLeading } from "@utils/string.utils";

@Injectable()
// @EventSubscriber()
export class AssetSubscriber implements EntitySubscriberInterface<Asset> {
    private manager: EntityManager;
    private entity: Asset;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(AssetRepo)
        private readonly assetRepo: AssetRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return Asset
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<Asset>) {
        this.manager = event.manager
        this.entity = event.entity
        try {

            await this.genCodeEntity()

        } catch (e) {
            console.log('beforeInsert Asset error: ', e)
        }
    }

    private async genCodeEntity() {
        const count = await this.manager.getRepository(Asset).count(
            {
                where: {
                    code: Not(IsNull())
                },
                withDeleted: true
            }
        )

        this.entity.code = `A${this.entity.department.code}${stringNumberWithZeroLeading(count + 1)}`
    }
}