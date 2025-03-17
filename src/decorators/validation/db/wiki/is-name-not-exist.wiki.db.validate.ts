import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { FilterRepo, VersionWikiRepo, WikiRepo } from "@repositories/index";
import { In, Not } from "typeorm";
import { DocumentWiki } from "@models/entities";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly wikiRepo: WikiRepo,
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        super()
        this.messageKey = 'DocumentWikiNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let folderId = args.object['IsNameNotExistWikiDbValidate_folderId']
        let wikiId = args.object['IsNameNotExistWikiDbValidate_wikiId']
        let versionWikiId = args.object['IsNameNotExistWikiDbValidate_versionWikiId']

        if (!wikiId && versionWikiId) {
            const versionWiki = await this.versionWikiRepo.createQueryBuilder('qb')
                .leftJoinAndSelect('qb.wiki', 'wiki')
                .where({id: versionWikiId})
                .getOne()

            wikiId = versionWiki?.wiki?.id
        }

        console.log('wikiId', wikiId)


        if (!folderId && !wikiId) {
            this.messageKey = !folderId ? 'DocumentFolderNotFound' : 'DocumentWikiNotFound'
            return false
        }

        let wiki: DocumentWiki
        if (!folderId) {
            if (args.object['wiki']) {
                folderId = args.object['wiki'].folder?.id
            } else {
                wiki = await this.wikiRepo.createQueryBuilder('qb')
                    .leftJoinAndSelect('qb.folder', 'folder')
                    .where({id: wikiId})
                    .getOne()

                if (!wiki) {
                    this.messageKey = 'DocumentWikiNotFound'
                    return false
                }

                folderId = wiki.folder.id
            }
        }

        const wikis = await this.wikiRepo.getAllOfFolderByFolderId(folderId)

        let wikiIds = wikis.map(i => i?.id)
        if (wikiId) {
            wikiIds = wikiIds.filter(i => i !== wikiId)
        }

        const data = await this.wikiRepo.createQueryBuilder()
            .where({
                id: In(wikiIds),
                name,
            })
            .getMany()

        return !data.length
    }
}

export function IsNameNotExistWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistWikiDbValidateConstraint,
        });
    };
}