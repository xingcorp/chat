import { Injectable } from '@nestjs/common';
import { ViewerTypeEnum, ViewTypeEnum } from "@enum/viewer/viewer.enum";
import { ViewerRepo } from "@repositories/viewer/viewer.repo";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class ViewerService {

    constructor(private readonly viewerRepo: ViewerRepo) {
    }

    async userHasViewing(param: { relationType: ViewTypeEnum; relationId: string }) {
        const {relationType, relationId} = param
        const args = {
            relationType,
            relationId,
            viewerType: ViewerTypeEnum.User,
            viewerId: await RequestContext.currentId()
        }
        let viewer = await this.viewerRepo.getBy(args)

        if (!viewer) {
            viewer = this.viewerRepo.create({
                ...args,
                count: 0
            })
        }

        viewer.count++

        await viewer.save()

        return viewer
    }

    async userHasViewingWiki(id: string) {
        return this.userHasViewing({
            relationId: id,
            relationType: ViewTypeEnum.Wiki
        })
    }

    async userHasViewingVersionWiki(id: string | undefined) {
        if (!id) return

        return this.userHasViewing({
            relationId: id,
            relationType: ViewTypeEnum.VersionWiki
        })
    }
}
