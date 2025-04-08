import { Controller, Get, HttpException, HttpStatus, Param, Query, Res, SetMetadata } from '@nestjs/common';
import { ObjectStoreService } from "@service-modules/object-store/object-store.service";
import { ViewObjectArgs } from "@service-modules/object-store/dto/object-store.args";
import { ServiceActions, ServiceKeys } from "@core/middleware/guard/service.action";

@Controller('object-store')
export class ObjectStoreController {

    constructor(private readonly objectStoreService: ObjectStoreService) {}

    @Get('view/:id')
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async getS3File(
        @Res() res: any,
        @Param('id') id: string,
        @Query() query: ViewObjectArgs
    ) {
        try {
            const url = await this.objectStoreService.getPreviewUrl(id, query)

            res.redirect(url)
        } catch (error) {
            console.error("ERR: ", error.message)
            throw new HttpException({
                status: false,
                message: error.baseMsg
            }, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
