import { Query, Resolver } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys } from "@core/middleware/guard/service.action";
import { MasterDataService } from "@modules/graphql/master-data/master-data.service";
import { IdentifyCardPlaceListResponse } from "@modules/graphql/master-data/dto/master-data.response";

@Resolver()
export class MasterDataResolver {

    constructor(private readonly masterDataService: MasterDataService) {
    }

    @Query(() => IdentifyCardPlaceListResponse, { name: 'identifyCardPlaceList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async identifyCardPlaceList(): Promise<IdentifyCardPlaceListResponse> {
        return this.masterDataService.identifyCardPlaceList()
    }
}
