import { Field, InputType, Int, } from '@nestjs/graphql'

@InputType()
export class CommonFilterGetListArgs {
  @Field(() => Int, { nullable: true, defaultValue: 0 })
  page: number

  @Field(() => Int, { nullable: true, defaultValue: 100 })
  size: number

  @Field(() => String, { nullable: true, defaultValue: null })
  keyword: string
}

@InputType()
export class CommonListFilterPaginate {
  @Field(() => Int, { nullable: true, defaultValue: 0 })
  page: number

  @Field(() => Int, { nullable: true, defaultValue: 20 })
  size: number
}

@InputType()
export class OnlyFilterKeywordArgs {
  @Field(() => String, { nullable: true, defaultValue: null })
  keyword: string
}

@InputType()
export class OnlyFilterKeywordWithNullPaginateArgs extends OnlyFilterKeywordArgs {
  @Field(() => Int, { nullable: true })
  page: number

  @Field(() => Int, { nullable: true })
  size: number
}
