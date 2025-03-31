import { Field, Float, ObjectType } from '@nestjs/graphql'
import { User } from './user'

@ObjectType()
export class NotificationRecord {
  @Field(() => String)
  id: string

  @Field(() => Float)
  createdAt: Date

  @Field(() => Float)
  updatedAt: Date

  @Field(() => String, { nullable: true })
  type: string

  @Field(() => String, { nullable: true })
  title: string

  @Field(() => String, { nullable: true })
  content: string

  @Field(() => String, { nullable: true })
  image: string

  @Field(() => [User], { nullable: true })
  receivers: User[]
}
