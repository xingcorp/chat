import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnLesson } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningLessonResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnLesson], { nullable: true })
    records?: LearnLesson[]
}