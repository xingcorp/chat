import * as dotenv from 'dotenv';

dotenv.config();
import { Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface } from "typeorm";
import { InfoBlock } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeInfoBlockRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { seedFieldWorkProfile } from "@models/seeds/work-profile/field.work-profile.seed";
import { BeforeQueryEvent } from "typeorm/subscriber/event/QueryEvent";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";

@Injectable()
// @EventSubscriber()
export class InfoBlockSubscriber implements EntitySubscriberInterface<InfoBlock> {

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(OfficeInfoBlockRepo)
        private readonly officeInfoBlockRepo: OfficeInfoBlockRepo,
        @Inject(RedisService)
        private readonly redisService: RedisService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return InfoBlock
    }

    async beforeQuery(event: BeforeQueryEvent<InfoBlock>) {
        /*if (!process.env.K_ORG_ID) return
        const key = CACHE_KEY.K_ORG_WORK_PROFILE
        const cached = await this.redisService.get(key)

        if (cached && cached === process.env.K_ORG_ID) {
            return
        }

        await this.redisService.set(key, process.env.K_ORG_ID)

        let block = await this.officeInfoBlockRepo.getWorkProfileByOrgId(process.env.K_ORG_ID)

        if (!block) {
            console.log('seedFieldWorkProfile')
            await seedFieldWorkProfile()
        }*/
    }
}