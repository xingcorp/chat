import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { AssetAudit } from "../entities/asset.audit"
import { Asset } from "../entities/asset/asset"
import { AssetAuditItem } from "../entities/asset.audit.item"
import { In } from "typeorm"
import { AssetAssignment } from "../entities/asset.assignment"
import { AssetAssignmentItem } from "../entities/asset.assignment.item"

@Resolver(_of => AssetAudit)
export class AssetAuditFieldResolver {
    constructor() { }

    @ResolveField('assets', _return => [Asset], { nullable: true })
    async assets(
        @Parent() root: AssetAudit
    ) {
        const auditItems = await AssetAuditItem.find({
            where: {
                auditId: root.id
            }
        })

        return Asset.find({ where: { id: In(auditItems.map(ai => ai.assetId)) } })
    }
}

@Resolver(_of => AssetAssignment)
export class AssetAssignmentFieldResolver {
    constructor() { }

    @ResolveField('assets', _return => [Asset], { nullable: true })
    async assets(
        @Parent() root: AssetAssignment
    ) {
        const items = await AssetAssignmentItem.find({
            where: {
                assignmentId: root.id
            }
        })

        return Asset.find({ where: { id: In(items.map(i => i.assetId)) } })
    }
}