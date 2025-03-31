import { forwardRef, Module } from '@nestjs/common'
import { CommonModule } from '../common/common.module'
import { StorageModule } from '../storage/storage.module'
import { AccessService } from './access/access.service'
import { IAMGraphQlClient } from './iam.client'
import { BankResolver } from './identity/bank.resolver'
import { CarrierResolver } from './identity/carrier.resolver'
import { CustomerService } from './identity/customer.service'
import { IdentityResolver } from './identity/identity.resolver'
import { IdentityService } from './identity/identity.service'
import { SysIdentityResolver } from './identity/sys.identity.resolver'
import { AppNotificationResolver } from './notification/app.notification.resolver'
import { NotificationService } from './notification/notification.service'
import { AddressResolver } from './organization/location/address.resolver'
import { BusinessRoleResolver } from './organization/business.role/business.role.resolver'
import { OrganizationResolver } from './organization/organization.resolver'
import { OrganizationService } from './organization/organization.service'
import { AddressService } from './organization/location/address.service'
import { BusinessRoleService } from './organization/business.role/business.role.service'
import { IAMPermissionService } from './access/permission/permission.service'
import { IAMPolicyActionService } from './access/permission/policy.action.service'
import { IAMPolicyEffectService } from './access/permission/policy.effect.service'
import { IAMPolicyResourceService } from './access/permission/policy.resource.service'
import { IAMPolicyServiceService } from './access/permission/policy.service.service'
import { IAMRoleService } from './access/role/role.service'
import { IAMPolicyService } from './access/permission/policy.service'
import { AccessResolver } from './access/access.resolver'
import { NotificationResolver } from './notification/notification.resolver'
import { OfficeOrgChartRepo } from '@models/repositories/office-org-chart.repo'
import { OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";
import { IsExistUserDbValidateConstraint } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { NotificationController } from './notification/notification.controller';
import { ModelModule } from '@models/model.module'

@Module({
  imports: [
    forwardRef(() => CommonModule),
    forwardRef(() => StorageModule),
  ],
  providers: [
    IAMGraphQlClient,
    IdentityResolver,
    SysIdentityResolver,
    OrganizationResolver,
    BusinessRoleResolver,
    AddressResolver,
    IdentityService,
    CustomerService,
    OrganizationService,
    AddressService,
    BusinessRoleService,
    BankResolver,
    CarrierResolver,
    NotificationService,
    AppNotificationResolver,
    NotificationResolver,
    IAMPolicyActionService,
    IAMPolicyEffectService,
    IAMPolicyResourceService,
    IAMPolicyServiceService,
    IAMPolicyService,
    IAMPermissionService,
    IAMRoleService,
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeUserRepo,
    AccessResolver,
    AccessService,
    AddressService,
    OfficeUserRepo,
    IsExistUserDbValidateConstraint,
  ],
  exports: [
    IdentityService,
    CustomerService,
    AccessService,
    OrganizationService,
    AddressService,
    BusinessRoleService,
    NotificationService,
    IAMPolicyActionService,
    IAMPolicyEffectService,
    IAMPolicyResourceService,
    IAMPolicyServiceService,
    IAMPolicyService,
    IAMPermissionService,
    IAMRoleService,
    AddressService,
    IAMGraphQlClient
  ],
  controllers: [NotificationController]
})
export class IAMModule { }
