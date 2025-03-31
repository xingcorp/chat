import { Field, Float, ObjectType } from '@nestjs/graphql'
import { BusinessRole } from './business.role'

@ObjectType()
export class ConfigurationMenuItem {
    @Field(() => String)
    id: string

    @Field(() => ConfigurationMenuItem, { nullable: true })
    paren: ConfigurationMenuItem

    @Field(() => [ConfigurationMenuItem], { nullable: true })
    childs: ConfigurationMenuItem[]

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    code: string

    @Field(() => String, { nullable: true })
    metadata: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => Float)
    createdAt: Date
  
    @Field(() => Float)
    updatedAt: Date
}

@ObjectType()
export class ConfigurationMenu {
    @Field(() => String)
    id: string
    
    @Field(() => BusinessRole, { nullable: false })
    businessRole: BusinessRole

    @Field(() => [ConfigurationMenuItem], { nullable: true })
    items: ConfigurationMenuItem[]

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => Float)
    createdAt: Date
  
    @Field(() => Float)
    updatedAt: Date
}
