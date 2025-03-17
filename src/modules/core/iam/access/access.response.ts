import { Field, ObjectType } from "@nestjs/graphql"
import { BusinessRole } from "../objects/business.role"
import { Organization } from "../objects/organization"
import { User } from "../objects/user"

@ObjectType()
export class StatementPolicy {
    @Field(() => String, { nullable: true })
    service: string

    @Field(() => String, { nullable: true })
    effect: string

    @Field(() => [String], { nullable: true })
    actions: string[]

    @Field(() => [String], { nullable: true })
    resources: string[]

    @Field(() => String, { nullable: true })
    condition: string
}

@ObjectType()
export class StatementMenu {
    id: string

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    code: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => String, { nullable: true })
    parentCode: string
}

@ObjectType()
export class AccessStatement {
    @Field(() => [StatementPolicy], { nullable: true })
    Allow: StatementPolicy[]

    @Field(() => [StatementPolicy], { nullable: true })
    Deny: StatementPolicy[]

    @Field(() => [StatementMenu], { nullable: true })
    Menus: StatementMenu[]
}

@ObjectType()
export class UserInfo {
    @Field(() => String, { nullable: false })
    userId: string

    @Field(() => User, { nullable: true })
    user: User

    @Field(() => String, { nullable: true })
    organizationId: string

    @Field(() => Organization, { nullable: true })
    organization: Organization

    @Field(() => String, { nullable: true })
    businessRoleId: string

    @Field(() => BusinessRole, { nullable: true })
    businessRole: BusinessRole

    @Field(() => [String], { nullable: true })
    businessRoleIds: string[]

    @Field(() => [BusinessRole], { nullable: true })
    businessRoles: BusinessRole[]
}

@ObjectType()
export class AccessPermission {
    @Field(() => String, { nullable: false })
    version: string

    @Field(() => String, { nullable: false })
    serviceCode: string

    @Field(() => UserInfo, { nullable: false })
    userInfo: UserInfo

    @Field(() => Boolean, { nullable: false })
    isRoot: boolean

    @Field(() => AccessStatement, { nullable: true })
    statement: AccessStatement
}
