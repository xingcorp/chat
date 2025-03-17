import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { UserWorkProfileInfo } from "@models/entities";
import { WorkProfileChangeTypeExplain } from "@enum/work-profile/work-profile.enum";
import { File } from "@core/storage/objects/file";
import { RequestContext } from "@common/context/request.context";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";

@Resolver(_of => UserWorkProfileInfo)
export class InfoWorkProfileResolver {

    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
    ) {
    }

    @ResolveField('typeTitle', _return => String, { nullable: true })
    typeTitle(
        @Parent() root: UserWorkProfileInfo
    ) {
        return WorkProfileChangeTypeExplain[root.type]
    }

    @ResolveField('attachments', _return => [File], {nullable: true})
    async attachments(
        @Parent() root: UserWorkProfileInfo
    ) {
        const {data} = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)

        return data?.files ?? []
    }
}
