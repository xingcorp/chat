import { Field, Float, InputType, Int, registerEnumType } from "@nestjs/graphql";

export enum OrderDirection {
    ASC = 'ASC',
    DESC = 'DESC'
}
registerEnumType(OrderDirection, { name: 'OrderDirection' })

@InputType()
export class DatePeriod {
    @Field(_type => Float, { nullable: true })
    start: number;

    @Field(_type => Float, { nullable: true })
    end: number;
}

@InputType()
export class NumberRange {
    @Field(_type => Float, { nullable: true })
    min: number;

    @Field(_type => Float, { nullable: true })
    max: number;
}

@InputType()
export class DefaultFilterInput {
    @Field(() => Int, { nullable: true })
    page: number

    @Field(() => Int, { nullable: true })
    size: number

    @Field({ nullable: true })
    keyword: string
}