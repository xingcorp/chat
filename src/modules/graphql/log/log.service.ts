import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { OfficeLogCommentArgs, OfficeLogHistoryArgs } from "@modules/graphql/log/dto/log.args";
import { OfficeLogRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { StorageService } from "@core/storage/storage.service";
import { OfficeFeatureLogType } from "@enum/logs/logs.enum";

@Injectable()
export class LogService {

    constructor(
        private readonly officeLogRepo: OfficeLogRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
    ) {
    }

    private async checkAttachments(attachmentIds: string[]) {
        for (const attachmentId of attachmentIds) {
            const {data, error} = await this.storageService.getFileDetail(RequestContext.currentToken(), attachmentId)
            if (error) throw error
            if (!data) throw OfficeError.FileNotExisted
        }
    }

    async commentCreate(param: OfficeLogCommentArgs) {
        if (param.attachmentIds) {
            await this.checkAttachments(param.attachmentIds)
        }

        if (param.imageIds) {
            await this.checkAttachments(param.imageIds)
        }

        const log = await this.officeLogRepo.commentCreate(param)

        return log.save()
    }

    async versionWikiCommentCreate(param: OfficeLogCommentArgs) {
        param.featureLogType = OfficeFeatureLogType.VersionWiki

        const log = await this.officeLogRepo.commentCreate(param)

        return log.save()
    }

    async wikiCommentCreate(param: OfficeLogCommentArgs) {
        param.featureLogType = OfficeFeatureLogType.Wiki

        const log = await this.officeLogRepo.commentCreate(param)

        return log.save()
    }

    async historyCreate(param: OfficeLogHistoryArgs) {
        const log = await this.officeLogRepo.historyCreate(param)

        return log.save()
    }
}
