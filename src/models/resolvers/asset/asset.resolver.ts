import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { Asset } from "@models/entities";
import { File } from "@core/storage/objects/file";
import { RequestContext } from "@common/context/request.context";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";

@Resolver(_of => Asset)
export class AssetFieldResolver {

    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
    ) {
    }
    @ResolveField('images', _return => [File], {nullable: true})
    async images(
        @Parent() root: Asset
    ) {
        const {data} = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.imageIds)

        return data?.files ?? []
    }

    @ResolveField('attachments', _return => [File], {nullable: true})
    async attachments(
        @Parent() root: Asset
    ) {
        const {data} = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)

        return data?.files ?? []
    }

}