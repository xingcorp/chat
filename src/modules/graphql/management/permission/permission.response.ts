import { PagingData } from "@models/base/paging.response"
import { OfficeSysUser } from "@models/entities/system.user"
import { Field, ObjectType } from "@nestjs/graphql"

@ObjectType({ implements: PagingData })
export class OfficeSysUserResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [OfficeSysUser], { nullable: true })
    sysUsers?: OfficeSysUser[]
}