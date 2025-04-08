import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { WarehouseAsset } from "@models/entities";

@ObjectType({ implements: PagingData })
export class WarehouseAssetListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [WarehouseAsset], { nullable: true })
    records?: WarehouseAsset[]
}