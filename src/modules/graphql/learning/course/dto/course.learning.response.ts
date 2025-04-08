import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnCourse } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningCourseResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnCourse], { nullable: true })
    records?: LearnCourse[]
}