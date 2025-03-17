import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { OfficeApproval, OfficeUser } from "../entities"
import { OfficeShoppingRequest } from "../entities/office.shopping.request"

@Resolver(_of => OfficeShoppingRequest)
export class ShoppingRequestFieldResolver {
    constructor() { }

    @ResolveField('shoppingApproval', _return => OfficeApproval, { nullable: true })
    async shoppingApproval(
        @Parent() root: OfficeShoppingRequest
    ) {
        if (root.approvalId) {
            return OfficeApproval.findOne({
                where: {
                    id: root.approvalId
                }
            })
        }

        return null
    }

    @ResolveField('requester', _return => OfficeUser, { nullable: true })
    async requester(
        @Parent() root: OfficeShoppingRequest
    ) {
        if (root.createdBy) {
            return OfficeUser.findOne({
                where: {
                    id: root.createdBy
                }
            })
        }

        return null
    }
}