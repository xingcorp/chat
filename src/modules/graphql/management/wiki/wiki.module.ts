import { forwardRef, Module } from '@nestjs/common';
import { WikiService } from './wiki.service';
import { WikiResolver } from './wiki.resolver';
import {
    IsExistFolderDocumentDbValidateConstraint
} from "@decorators/validation/db/document/folder/is-exist.folder.document.db.validate";
import {
    CategoryWikiRepo,
    FolderDocumentRepo, OfficeApprovalRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo, OfficeUserRepo, TagDocumentRepo,
    VersionWikiRepo,
    WikiRepo
} from "@models/repositories";
import { ApprovalModule } from "@modules/graphql/approval/approval.module";
import {
    IsNameNotExistWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/is-name-not-exist.wiki.db.validate";
import { IsExistAttachmentsIamValidateConstraint } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { StorageModule } from "@core/storage/storage.module";
import { IsExistWikiDbValidateConstraint } from "@decorators/validation/db/wiki/wiki/is-exist.wiki.db.validate";
import {
    IsCanCreateNewVersionWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/is-can-create-new-version.wiki.db.validate";
import { LogModule } from "@modules/graphql/log/log.module";
import {
    IsExistVersionWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/version/is-exist.version.wiki.db.validate";
import { OfficeOrgChartDocumentRepo } from "@repositories/office-org-chart-document.repo";
import { ClientWikiResolver } from './client.wiki.resolver';
import { CommonModule } from "@core/common/common.module";
import { CategoryService } from './category/category.service';
import { CategoryResolver } from './category/category.resolver';
import {
    IsNameNotExistCategoryWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/category/is-name-not-exist.category.wiki.db.validate";
import {
    IsExistCategoryWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/category/is-exist.category.wiki.db.validate";
import {
    IsCanUpdateApprovalDbValidateConstraint
} from "@decorators/validation/db/approval/approval/is-can-update.approval.db.validate";
import { ViewerModule } from "@modules/graphql/viewer/viewer.module";
import {
    IsExistAndGetUserDbValidateConstraint
} from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";
import {
    IsExistTagDocumentDbValidateConstraint
} from "@decorators/validation/db/document/tag/is-exist.tag.document.db.validate";
import {
    IsCodeNotExistWikiDbValidateConstraint
} from "@decorators/validation/db/wiki/is-code-not-exist.wiki.db.validate";

@Module({
    imports: [
        forwardRef(() => StorageModule),
        ApprovalModule,
        LogModule,
        forwardRef(() => CommonModule),
        forwardRef(() => ViewerModule),
    ],
    providers: [
        WikiService,
        WikiResolver,
        ClientWikiResolver,
        CategoryService,
        CategoryResolver,
        FolderDocumentRepo,
        WikiRepo,
        VersionWikiRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeUserRepo,
        OfficeOrgChartDocumentRepo,
        CategoryWikiRepo,
        OfficeApprovalRepo,
        TagDocumentRepo,
        IsExistFolderDocumentDbValidateConstraint,
        IsNameNotExistWikiDbValidateConstraint,
        IsExistAttachmentsIamValidateConstraint,
        IsExistWikiDbValidateConstraint,
        IsCanCreateNewVersionWikiDbValidateConstraint,
        IsExistVersionWikiDbValidateConstraint,
        IsNameNotExistCategoryWikiDbValidateConstraint,
        IsExistCategoryWikiDbValidateConstraint,
        IsCanUpdateApprovalDbValidateConstraint,
        IsExistAndGetUserDbValidateConstraint,
        IsExistTagDocumentDbValidateConstraint,
        IsCodeNotExistWikiDbValidateConstraint,
    ]
})
export class WikiModule {
}
