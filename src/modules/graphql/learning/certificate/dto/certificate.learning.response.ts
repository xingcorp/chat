import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnCertification } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningCertificateResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnCertification], { nullable: true })
    records?: LearnCertification[]
}