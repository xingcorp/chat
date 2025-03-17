import { Field, InputType, OmitType } from "@nestjs/graphql";
import { ApprovalArgs } from "@modules/graphql/approval/approval.args";
import { CategoryWiki, DocumentFolder, DocumentWiki, OfficeApproval, TagDocument, VersionWiki } from "@models/entities";
import {
    IsExistFolderDocumentDbValidate
} from "@decorators/validation/db/document/folder/is-exist.folder.document.db.validate";
import { Expose, Transform, Type } from "class-transformer";
import { IsExistAttachmentsIamValidate } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { IsNameNotExistWikiDbValidate } from "@decorators/validation/db/wiki/is-name-not-exist.wiki.db.validate";
import { IsExistWikiDbValidate } from "@decorators/validation/db/wiki/wiki/is-exist.wiki.db.validate";
import { UpdateTypeEnum, VersionWikiStatus, WikiImportant } from "@enum/wiki/wiki.enum";
import {
    IsCanCreateNewVersionWikiDbValidate
} from "@decorators/validation/db/wiki/is-can-create-new-version.wiki.db.validate";
import { ValidateIf, ValidateNested } from "class-validator";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { CommonCommentCreateInput } from "@args/logs/office-logs.args";
import { IsExistVersionWikiDbValidate } from "@decorators/validation/db/wiki/version/is-exist.version.wiki.db.validate";
import { WikiFilter } from "@args/wiki/args.wiki";
import {
    IsExistCategoryWikiDbValidate
} from "@decorators/validation/db/wiki/category/is-exist.category.wiki.db.validate";
import {
    IsCanUpdateApprovalDbValidate
} from "@decorators/validation/db/approval/approval/is-can-update.approval.db.validate";
import { UserDocumentPermissionInput } from "@args/document/args.document";
import { IsExistTagDocumentDbValidate } from "@decorators/validation/db/document/tag/is-exist.tag.document.db.validate";
import { IsCodeNotExistWikiDbValidate } from "@decorators/validation/db/wiki/is-code-not-exist.wiki.db.validate";
import { IsMaxLengthValidate } from "@decorators/validation/utils/is-max-length.validate";


@InputType()
export class WikiCreateInput {
    @Field({ nullable: false })
    @IsExistFolderDocumentDbValidate()
    folderId: string

    folder?: DocumentFolder

    @Expose()
    @Transform(({ obj }) => obj.folderId)
    IsNameNotExistWikiDbValidate_folderId?: string = null

    @Expose()
    @Transform(({ obj }) => obj.wikiId)
    IsNameNotExistWikiDbValidate_wikiId?: string = null

    @Expose()
    @Transform(({ obj }) => obj.versionDraftId)
    IsNameNotExistWikiDbValidate_versionWikiId?: string = null

    @Field({ nullable: true })
    @IsNameNotExistWikiDbValidate()
    name: string

    @Expose()
    @Transform(({ obj }) => obj.wikiId)
    IsCodeNotExistWikiDbValidate_wikiId?: string = null

    @Expose()
    @Transform(({ obj }) => obj.versionDraftId)
    IsCodeNotExistWikiDbValidate_versionWikiId?: string = null

    @Field({ nullable: true })
    @ValidateIf(o => o.code)
    @IsCodeNotExistWikiDbValidate()
    @IsMaxLengthValidate(40, {
        message: 'MaxLengthField::Mã tài liệu::40'
    })
    code: string

    @Field({ nullable: true })
    content: string

    @Field(() => VersionWikiStatus, { nullable: true, defaultValue: VersionWikiStatus.UnderReview })
    status: VersionWikiStatus

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.thumbnailIds && o.thumbnailIds.length)
    @IsExistAttachmentsIamValidate()
    thumbnailIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.attachmentIds && o.attachmentIds.length)
    @IsExistAttachmentsIamValidate()
    attachmentIds: string[]

    @Field(() => ApprovalArgs, { nullable: true })
    @ValidateIf(o => o.status === VersionWikiStatus.UnderReview)
    @IsDefinedValidate({
        message: 'NeedApproval'
    })
    approvalArgs: ApprovalArgs

    @Field({ nullable: true })
    @ValidateIf(o => o.versionDraftId)
    @IsExistVersionWikiDbValidate()
    versionDraftId: string

    versionDraft?: VersionWiki

    @Field({ nullable: true })
    @ValidateIf(o => o.versionRevertId)
    @IsExistVersionWikiDbValidate()
    versionRevertId: string

    versionRevert?: VersionWiki

    @Field(() => WikiImportant, { nullable: true })
    important: WikiImportant

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.categoryWikiIds)
    @IsExistCategoryWikiDbValidate()
    categoryWikiIds: string[]

    categoryWikis?: CategoryWiki[] = []

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.tagIds)
    @IsExistTagDocumentDbValidate()
    tagIds: string[]

    tags?: TagDocument[] = []

    @Field(() => UserDocumentPermissionInput, { nullable: true })
    @ValidateNested({ each: true })
    @Type(() => UserDocumentPermissionInput)
    permissions?: UserDocumentPermissionInput
}

@InputType()
export class WikiUpdateInput extends WikiCreateInput {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.approvalId)
    @IsCanUpdateApprovalDbValidate()
    approvalId: string

    approval?: OfficeApproval

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.versionWikiId)
    @IsExistVersionWikiDbValidate()
    versionWikiId: string

    versionWiki?: VersionWiki
}

@InputType()
export class WikiSetImportantInput {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Field(() => WikiImportant, { nullable: true })
    important: WikiImportant
}

@InputType()
export class WikiInfoUpdateInput {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Field(() => WikiImportant, { nullable: true })
    important?: WikiImportant

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.categoryWikiIds)
    @IsExistCategoryWikiDbValidate()
    categoryWikiIds?: string[]

    categoryWikis?: CategoryWiki[] = []

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.tagIds)
    @IsExistTagDocumentDbValidate()
    tagIds?: string[]

    tags?: TagDocument[] = []

    @Field(() => UserDocumentPermissionInput, { nullable: true })
    @ValidateNested({ each: true })
    @Type(() => UserDocumentPermissionInput)
    permissions: UserDocumentPermissionInput
}

@InputType()
export class WikiNewVersionCreateInput extends OmitType(WikiCreateInput, ['folderId', 'important', 'categoryWikiIds']) {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    @IsCanCreateNewVersionWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Field(() => UpdateTypeEnum, { nullable: true })
    @ValidateIf(o => o.status === VersionWikiStatus.UnderReview)
    @IsDefinedValidate({
        message: 'VersionWikiUpdateNeedUpdateType'
    })
    updateType: UpdateTypeEnum

    @Expose()
    @Transform(({ obj }) => obj.wikiId)
    IsNameNotExistWikiDbValidate_wikiId?: string = null
}

@InputType()
export class WikiNewVersionRevertInput {
    @Field({ nullable: false })
    @IsExistVersionWikiDbValidate()
    versionRevertId: string

    versionRevert?: VersionWiki

    @Field(() => UpdateTypeEnum, { nullable: true })
    @IsDefinedValidate({
        message: 'VersionWikiUpdateNeedUpdateType'
    })
    updateType: UpdateTypeEnum
}


@InputType()
export class WikiNewVersionUpdateInput extends OmitType(WikiNewVersionCreateInput, ['wikiId']) {
    @Field(_type => String, { nullable: false })
    @IsExistVersionWikiDbValidate()
    versionWikiId: string

    versionWiki?: VersionWiki
}

@InputType()
export class ManageWikiFilter extends WikiFilter {
}

@InputType()
export class VersionWikiCommentCreateInput extends CommonCommentCreateInput {
    @Field(_type => String, { nullable: false })
    @IsExistVersionWikiDbValidate()
    versionWikiId: string

    versionWiki?: VersionWiki
}


@InputType()
export class WikiCommentCreateInput extends CommonCommentCreateInput {
    @Field(_type => String, { nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: VersionWiki
}

@InputType()
export class OfficeWikiFilter extends WikiFilter {
}

@InputType()
export class WikiCopyCreateInput {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Field({ nullable: false })
    @IsExistFolderDocumentDbValidate()
    folderIds: string

    folders?: DocumentFolder[]
}

@InputType()
export class WikiMoveInput {
    @Field({ nullable: false })
    @IsExistWikiDbValidate()
    wikiId: string

    wiki?: DocumentWiki

    @Expose()
    @Transform(({ obj }) => obj.folderId)
    IsNameNotExistWikiDbValidate_folderId?: string = null

    @Expose()
    @Transform(({ obj }) => obj.wikiId)
    IsNameNotExistWikiDbValidate_wikiId?: string = null

    @Field({ nullable: false })
    @IsExistFolderDocumentDbValidate()
    @IsNameNotExistWikiDbValidate()
    folderId: string

    folder?: DocumentFolder
}

@InputType()
export class VersionWikiCopyCreateInput {
    @Field(_type => String, { nullable: false })
    @IsExistVersionWikiDbValidate()
    versionWikiId: string

    versionWiki?: VersionWiki

    @Field({ nullable: false })
    @IsExistFolderDocumentDbValidate()
    folderIds: string

    folders?: DocumentFolder[]
}