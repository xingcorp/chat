import { Field, InputType, Int } from "@nestjs/graphql";
import { LearnCertification } from "@models/entities";
import { Expose, Transform } from "class-transformer";
import { ValidateIf } from "class-validator";
import { DefaultFilterInput } from "@common/args.common";
import {
    IsNameNotExistCertificateLearningDbValidate
} from "@decorators/validation/db/learning/certificate/is-name-not-exist.certificate.learning.db.validate";
import {
    IsExistCertificateLearningDbValidate
} from "@decorators/validation/db/learning/certificate/is-exist.certificate.learning.db.validate";

@InputType()
export class LearningCertificateCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistCertificateLearningDbValidate()
    name: string
}

@InputType()
export class LearningCertificateUpdateInput extends LearningCertificateCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistCertificateLearningDbValidate()
    certificateId: string

    certificate?: LearnCertification

    @Expose()
    @Transform(({obj}) => obj.certificateId)
    IsNameNotExistCertificateLearningDbValidate_certificateId?: string = null
}

@InputType()
export class LearningCertificateUpsertInput extends LearningCertificateUpdateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.certificateId)
    @IsExistCertificateLearningDbValidate()
    certificateId: string
}

@InputType()
export class LearningCertificateFilterInput extends DefaultFilterInput {}