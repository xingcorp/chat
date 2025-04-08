import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForward, ApprovalForwardUser, OfficeApproval, OfficeUser } from "@models/entities";

@Resolver(_of => ApprovalForward)
export class ApprovalForwardResolver {
    private getThis(root: ApprovalForward, relations: string[] = []) {
        return ApprovalForward.findOne({
            relations,
            where: {id: root.id}
        })
    }

    @ResolveField('users', _return => [ApprovalForwardUser], {nullable: true})
    async users(
        @Parent() root: ApprovalForward
    ) {
        const _this = await this.getThis(root, ['users'])

        return _this.users
    }

    @ResolveField('approval', _return => OfficeApproval, {nullable: true})
    async approval(
        @Parent() root: ApprovalForward
    ) {
        const _this = await this.getThis(root, ['approval'])

        return _this.approval
    }

    @ResolveField('originApproval', _return => OfficeApproval, {nullable: true})
    async originApproval(
        @Parent() root: ApprovalForward
    ) {
        const _this = await this.getThis(root, ['originApproval'])

        return _this.originApproval
    }

    @ResolveField('creator', _return => OfficeUser, {nullable: true})
    async creator(
        @Parent() root: ApprovalForward
    ) {
        if (!root.createdBy) return null

        return OfficeUser.findOneBy({id: root.createdBy})
    }
}