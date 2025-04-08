import { Controller, Get, HttpException, HttpStatus, Inject, Param, Query, Res, forwardRef } from "@nestjs/common";
import { ViewDocumentArgs } from "./document.args";
import { DocumentService } from "./document.service";

@Controller()
export class DocumentController {
    constructor(
        @Inject(forwardRef(() => DocumentService))
        private readonly documentService: DocumentService,
    ) {
    }

    @Get('storage/:id')
    async getS3File(
        @Res() res: any,
        @Param('id') id: string,
        @Query() query: ViewDocumentArgs
    ) {
        try {
            const url = await this.documentService.getDocumentPreviewUrl(id, query)

            res.redirect(url)
        } catch (error) {
            console.error("ERR: ", error.message)
            throw new HttpException({
                status: false,
                message: error.baseMsg
            }, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('storage/restore/size')
    async restoreSizeLossInfo() {
        try {
            return this.documentService.restoreSize()
        } catch (error) {
            console.error("ERR: ", error.message)
            throw new HttpException({
                status: false,
                message: error.baseMsg
            }, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}