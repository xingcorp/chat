import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { CategoryAsset } from "@models/entities";

@ObjectType({ implements: PagingData })
export class CategoryAssetListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [CategoryAsset], { nullable: true })
    records?: CategoryAsset[]
}