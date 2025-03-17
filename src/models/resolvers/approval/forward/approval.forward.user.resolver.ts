import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForward, ApprovalForwardUser, OfficeUser } from "@models/entities";

@Resolver(_of => ApprovalForwardUser)
export class ApprovalForwardUserResolver {
    private getThis(root: ApprovalForwardUser, relations: string[] = []) {
        return ApprovalForwardUser.findOne({
            relations,
            where: {id: root.id}
        })
    }

    @ResolveField('forward', _return => ApprovalForward, {nullable: true})
    async forward(
        @Parent() root: ApprovalForwardUser
    ) {
        const _this = await this.getThis(root, ['forward'])

        return _this.forward
    }

    @ResolveField('user', _return => OfficeUser, {nullable: true})
    async user(
        @Parent() root: ApprovalForwardUser
    ) {
        const _this = await this.getThis(root, ['user'])

        return _this.user
    }
}