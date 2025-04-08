import * as dotenv from 'dotenv';
dotenv.config();

import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { DocumentController } from "./document.controller";
import { IAMGraphQlClient } from "src/modules/core/iam/iam.client";
import { DocumentStoreGCloudService } from "./store/document-store.g-cloud.service";
import { DocumentService } from './document.service';
import { DocumentResolver } from './document.resolver';
import { DocumentStoreAwsService } from "./store/document-store.aws.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { DocumentFile, DocumentFolder, OfficeOrgChart, OrgChartDocument } from "@models/entities";
import { STORE_SERVICE } from "./store/document-store-interface.interface";
import { CommonModule } from "@core/common/common.module";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeOrgChartDocumentRepo } from "@models/repositories/office-org-chart-document.repo";
import {
    OfficeSysUserRepo,
    OfficeUserRepo,
    TagDocumentRepo,
    UserDepartmentRepo,
    VersionWikiRepo,
    WikiRepo
} from "@models/repositories";
import { TagService } from './tag/tag.service';
import { TagResolver } from './tag/tag.resolver';
import {
    IsExistTagDocumentDbValidateConstraint
} from "@decorators/validation/db/document/tag/is-exist.tag.document.db.validate";
import {
    IsNameNotExistTagDocumentDbValidateConstraint
} from "@decorators/validation/db/document/tag/is-name-not-exist.tag.document.db.validate";

const getDocumentStoreService = () => {
    switch (process.env.DOCUMENT_STORE_SERVICE) {
        case STORE_SERVICE.GCLOUD:
            return DocumentStoreGCloudService;
        case STORE_SERVICE.AWS:
        default:
            return DocumentStoreAwsService;
    }
}

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        forwardRef(() => CommonModule),
        TypeOrmModule.forFeature([
            DocumentFolder,
            DocumentFile,
            OfficeOrgChart,
            OrgChartDocument
        ])
    ],
    controllers: [
        DocumentController
    ],
    providers: [
        IAMGraphQlClient,
        {
            provide: 'DocumentStoreService',
            useClass: getDocumentStoreService()
        },
        DocumentService,
        DocumentResolver,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeOrgChartDocumentRepo,
        WikiRepo,
        VersionWikiRepo,
        UserDepartmentRepo,
        TagDocumentRepo,
        TagService,
        TagResolver,
        IsExistTagDocumentDbValidateConstraint,
        IsNameNotExistTagDocumentDbValidateConstraint
    ],
    exports: [
        DocumentService,
    ]
})
export class DocumentModule { }