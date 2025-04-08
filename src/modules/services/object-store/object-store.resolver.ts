import { Args, Mutation, registerEnumType, Resolver } from '@nestjs/graphql';
import { Inject, SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { OfficeRequesterId, RequesterId } from "@core/middleware/decorator/user.decorator";
import { ObjectStoreService } from "@service-modules/object-store/object-store.service";
import { OfficeObjectStoreGenLinkUpload } from "@service-modules/object-store/dto/object-store.response";
import { OfficeObject } from "@models/entities/object-store/office-object";
import { OfficeObjectType } from "@enum/object-store/object-store.enum";
import { gcpStorageGetListFiles, gcpStorageMoveFile } from "@services/g-cloud/store.g-cloud";
import { getPathAndNameAndExtFile } from "@utils/file.utils";
import { RandomHelper } from "@common/random";

registerEnumType(OfficeObjectType, { name: 'OfficeObjectType' })

@Resolver()
export class ObjectStoreResolver {

    constructor(
        @Inject(ObjectStoreService)
        private readonly objectStoreService: ObjectStoreService
    ) {
    }

    @Mutation(() => OfficeObjectStoreGenLinkUpload, { name: 'officeObjectStoreGenLinkUpload' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async officeObjectStoreGenLinkUpload(
        @Args({ name: 'filename', type: () => String }) filename: string,
        @Args({ name: 'officeType', type: () => OfficeObjectType }) officeType: OfficeObjectType,
        @Args({ name: 'mimetype', type: () => String }) mimetype: string,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeObjectStoreGenLinkUpload> {
        return this.objectStoreService.genLinkUpload({filename, officeType, mimetype}, userId);
    }

    @Mutation(() => OfficeObject, { name: 'officeObjectStoreUploadSuccess' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async officeObjectStoreUploadSuccess(
        @Args({ name: 'path', type: () => String }) path: string,
        @Args({ name: 'filename', type: () => String }) filename: string,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeObject> {
        return this.objectStoreService.officeStoreUploadSuccess({path, filename}, userId);
    }
}
