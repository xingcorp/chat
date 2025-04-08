import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { CheckInPlace, WhitelistIP } from "../entities"

@Resolver(_of => CheckInPlace)
export class CheckInPlaceFieldResolver {
    constructor() { }

    @ResolveField('publicIPs', _return => [String], { nullable: true })
    async pathName(
        @Parent() root: CheckInPlace
    ) {
        if (root.ipValidation === true) {
            const whitelist = await WhitelistIP.find()
            return whitelist.map(w => w.publicIp)
        }

        return null
    }
}