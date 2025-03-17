import { Module } from '@nestjs/common';
import { CertificateLearningService } from './certificate.learning.service';
import { CertificateLearningResolver } from './certificate.learning.resolver';
import { OfficeCertificateLearningResolver } from './office.certificate.learning.resolver';
import {
    IsExistCertificateLearningDbValidateConstraint
} from "@decorators/validation/db/learning/certificate/is-exist.certificate.learning.db.validate";
import {
    IsNameNotExistCertificateLearningDbValidateConstraint
} from "@decorators/validation/db/learning/certificate/is-name-not-exist.certificate.learning.db.validate";
import { CertificateLearningRepo, OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";

@Module({
    providers: [
        CertificateLearningService,
        CertificateLearningResolver,
        OfficeCertificateLearningResolver,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeUserRepo,
        CertificateLearningRepo,
        IsExistCertificateLearningDbValidateConstraint,
        IsNameNotExistCertificateLearningDbValidateConstraint,
    ]
})
export class CertificateLearningModule {
}
