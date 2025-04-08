import { Field, Float, ObjectType } from '@nestjs/graphql'
import { User } from './user'
import { File } from '@core/storage/objects/file'

@ObjectType()
export class Notification {
  @Field(() => String)
  id: string

  @Field(() => String, { nullable: true })
  type: string

  @Field(() => String, { nullable: true })
  title: string

  @Field(() => String, { nullable: true })
  content: string

  @Field(() => String, { nullable: true })
  image: string

  @Field(() => String, { nullable: true })
  metadata: string

  @Field(() => Boolean, { nullable: false, defaultValue: false })
  isRead: boolean

  @Field(() => User, { nullable: true })
  receiver: User

  @Field(() => User, { nullable: true })
  sender: User

  @Field(() => Float, { nullable: true })
  createdAt: Date

  @Field(() => Float, { nullable: true })
  updatedAt: Date

  @Field(() => [File], { nullable: true })
  attachFiles: File[]

  @Field(() => [File], { nullable: true })
  images: File[]
}
