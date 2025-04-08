import { Parent, registerEnumType, ResolveField, Resolver } from "@nestjs/graphql";
import GraphQLJSON from "graphql-type-json";
import { InfoBlock, InfoField } from "../entities";
import { OfficeBlockType } from "@enum/block/block.enum";
import { BlockFieldType, LinkFieldType, LinkTableType } from "@enum/block/field.enum";

registerEnumType(BlockFieldType, {name: 'BlockFieldType'})

@Resolver(_of => InfoField)
export class InfoFieldFieldResolver {
    constructor() { }

    @ResolveField('block', _return => InfoBlock, { nullable: true })
    async block(
        @Parent() root: InfoField
    ) {
        if (root.blockId) {
            return InfoBlock.findOne({
                where: {
                    id: root.blockId,
                    relationType: OfficeBlockType.User
                }
            })
        }

        return null
    }

    @ResolveField('value', _return => GraphQLJSON, { nullable: true })
    async value(
        @Parent() root: InfoField
    ) {
        if (root.officeUserExtraData) {
            return root.officeUserExtraData[root.code]
        }
        return null
    }

    @ResolveField('fieldType', _return => BlockFieldType, { nullable: true })
    async fieldType(
        @Parent() root: InfoField
    ) {
        if (root.linkTableType) {
            switch (root.linkTableType) {
                case LinkTableType.User:
                    return this.fieldTypeGetUserType(root.linkFieldType)
                default:
                    return BlockFieldType.Default
            }
        }

        return BlockFieldType.Default
    }

    private fieldTypeGetUserType(linkFieldType: LinkFieldType) {
        switch (linkFieldType) {
            case LinkFieldType.leaveOn:
            case LinkFieldType.resignationType:
            case LinkFieldType.lastWorkingOn:
            case LinkFieldType.resignationDetailReason:
            case LinkFieldType.resignationReason:
                return BlockFieldType.Resign
            default:
                return BlockFieldType.Default
        }
    }
}