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
export class IsCodeNotExistWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly wikiRepo: WikiRepo,
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        super()
        this.messageKey = 'DocumentWikiCodeExisted'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        let wikiId = args.object['IsCodeNotExistWikiDbValidate_wikiId']
        let versionWikiId = args.object['IsCodeNotExistWikiDbValidate_versionWikiId']

        if (!wikiId && versionWikiId) {
            const versionWiki = await this.versionWikiRepo.createQueryBuilder('qb')
                .leftJoinAndSelect('qb.wiki', 'wiki')
                .where({id: versionWikiId})
                .getOne()

            wikiId = versionWiki?.wiki?.id
        }

        if (wikiId) {
            const wiki = await this.wikiRepo.createQueryBuilder('qb')
                .leftJoinAndSelect('qb.orgCharts', 'orgCharts')
                .where({id: wikiId})
                .getOne()

            if (!wiki) {
                this.messageKey = 'DocumentWikiNotFound'
                return false
            }

            return !(await this.wikiRepo.getBy({
                id: Not(wikiId),
                code
            }, ['orgCharts']))
        }

        const orgCharts = await RequestContext.getRootOrgIds()

        return !(await this.wikiRepo.getBy({
            code
        }, ['orgCharts']))
    }
}

export function IsCodeNotExistWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeNotExistWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeNotExistWikiDbValidateConstraint,
        });
    };
}