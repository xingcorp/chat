import { Field, Float, ObjectType } from '@nestjs/graphql'
import { BusinessRole } from './business.role'
import { ConfigurationMenu } from './configuration.menu'

@ObjectType()
export class Configuration {
    @Field(() => String)
    id: string

    @Field(() => [BusinessRole], { nullable: true })
    businessRoles: BusinessRole[]

    @Field(() => [ConfigurationMenu], { nullable: true })
    menu: [ConfigurationMenu]

    @Field(() => Float)
    createdAt: Date
  
    @Field(() => Float)
    updatedAt: Date
}
