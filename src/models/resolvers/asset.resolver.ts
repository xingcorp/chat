import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { Asset } from "../entities/asset/asset"
import { OfficeOrgChart, OfficeUser } from "../entities"
import { AssetOwner } from "../entities/asset.owner"

@Resolver(_of => Asset)
export class AssetFieldResolver {
    constructor() { }

    /*@ResolveField('department', _return => OfficeOrgChart, { nullable: true })
    async subcribers(
        @Parent() root: Asset
    ) {
        if (root.departmentId) {
            return OfficeOrgChart.findOne({
                where: {
                    id: root.departmentId
                }
            })
        }

        return null
    }*/

    /*@ResolveField('officeUser', _return => OfficeUser, { nullable: true })
    async officeUser(
        @Parent() root: Asset
    ) {
        if (root.supplyId) {
            const assetOwner = await AssetOwner.findOne( {
                where: {
                    id: root.supplyId
                }
            })
            let user = null
            if (assetOwner && assetOwner.ownerId) {
                user = await OfficeUser.findOne({
                    where: {
                        id: assetOwner.ownerId
                    }
                })
            }

            return user
        }

        return null
    }*/
}