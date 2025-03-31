import { ObjectType, Field, Int } from '@nestjs/graphql'
import { Organization } from '../objects/organization'

@ObjectType()
export class OrganizationResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [Organization], { nullable: true })
  organizations?: Organization[]
}
