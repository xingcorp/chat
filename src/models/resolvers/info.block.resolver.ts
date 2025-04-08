import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { InfoBlock, InfoField } from "../entities";
import { ObjectStatus } from "../entities/profile.info.block";
import { RequestContext } from "@common/context/request.context";

@Resolver(_of => InfoBlock)
export class InfoBlockFieldResolver {
    constructor() { }

    @ResolveField('fields', _return => [InfoField], { nullable: true })
    async fields(
        @Parent() root: InfoBlock
    ) {
        const where = {
            blockId: root.id
        }

        if (!RequestContext.isSysUser()) {
            where['status'] = ObjectStatus.Active
        }

        const fields = await InfoField.find({
            where: where,
            order: {
                order: "ASC"
            }
        })

        fields.forEach(field => {
            field.officeUserExtraData = root.officeUserExtraData
        })

        return fields
    }

    @ResolveField('appFields', _return => [InfoField], { nullable: true })
    async appFields(
        @Parent() root: InfoBlock
    ) {
        const fields = await InfoField.find({
            where: {
                blockId: root.id,
                status: ObjectStatus.Active
            },
            order: {
                order: "ASC"
            }
        })

        fields.forEach(field => {
            field.officeUserExtraData = root.officeUserExtraData
        })

        return fields
    }
}