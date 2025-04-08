export const Sharitek = 'sharitek'
export const ActionKey = 'ServiceAction'
export const OrganizationKey = 'OrganizationKey'
export const BusinessRoleKey = 'BusinessRoleCodeKey'
export const ServiceKeys = {
  Action: 'ServiceAction',
  Organization: 'OrganizationKey',
  BusinessRole: 'BusinessRoleCodeKey',
  UserType: 'UserTypeKey'
}

export const ServiceRedisKey = {
  User: 'Service_user_redis_key_'
}

export const BusinessRoleCodes = {
  ADMINISTRATOR: 'ADMINISTRATOR',
  ALL: 'ALL',
  COMPANY: 'COM',
  DISTRIBUTOR: 'DIS',
  SHOP: 'SHO',
  TECHNICIAN: 'KTV',
  SALE: 'SAL',
  SALEB2C: 'SALEB2C',
  SALEB2B: 'SALEB2B',
  COLLABORATOR: 'CTV',
  COLLABORATORB2B: 'CTVB2B',
  COLLABORATORB2C: 'CTVB2C',
  TECHNICIAN_LEADER: 'KTV_LEADER',
  CUSTOMER_CARE: 'CSKH',
  COMPLAIN_HANDLER: 'CVGQKN',
  COMPLAIN_RESOLVER: 'NVNKN',
  WARRANTY_ADMINISTRATOR: 'WARRANTY_ADMINISTRATOR',
  WAREHOUSE_ADMINISTRATOR: 'WAREHOUSE_ADMINISTRATOR',
  HEAD_OF_DIVISION: 'HEAD_OF_DIVISION',
  MANAGER_3T: 'MANAGER_3T',
  SUPERVISOR: 'SUPERVISOR',
}

export const UserType = {
  SYSTEM_USER: 'SYSTEM_USER',
  NORMAL_USER: 'NORMAL_USER'
}

export const ServiceActions = {
  Public: 'policy:public',
  Authenticated: 'policy:authenticated',
  SystemAdmin: 'policy.systemadmin',

  //Lead
  LeadCreate: 'lead:create',
  LeadView: 'lead:view',
  LeadUpdate: 'lead:update',
  LeadDelete: 'lead:delete',
  LeadImport: 'lead:import',
  LeadExport: 'lead:export',
  LeadReport: 'lead:report',
  LeadSearch: 'lead:search',

  //Deal
  DealCreate: 'deal:create',
  DealView: 'deal:view',
  DealEdit: 'deal:edit',
  DealDelete: 'deal:delete',
  DealImport: 'deal:import',
  DealExport: 'deal:export',
  DealReport: 'deal:report',
  DealSearch: 'deal:search',

  //Delivery
  DeliveryCreate: 'delivery:create',
  DeliveryView: 'delivery:view',
  DeliveryEdit: 'delivery:edit',
  DeliveryDelete: 'delivery:delete',
  DeliveryImport: 'delivery:import',
  DeliveryExport: 'delivery:export',
  DelieveryReport: 'delivery:report',
  DeliverySearch: 'delivery:search',

  //Installation
  InstallationCreate: 'installation:create',
  InstallationView: 'installation:view',
  InstallationEdit: 'installation:edit',
  InstallationDelete: 'installation:delete',
  InstallationImport: 'installation:import',
  InstallationExport: 'installation:export',
  InstallationReport: 'installation:report',
  InstallationSearch: 'installation:search',

  //Management
  ManagementGeneral: 'management:general',
  ManagementSchedule: 'management:schedule',
  ManagementCustomer: 'management:customer',
  ManagementUser: 'management:user',

  PermissionCreate: 'permission:create',
  PermissionRemove: 'permission:remove',

  //Product
  ProductImport: 'product.import',
  ProductCreate: 'product.create',
  ProductRemove: 'product.remove',
  ProductView: 'product.view',

  //Trouble
  TroubleView: 'trouble.view',
  TroubleCreate: 'trouble.create',
  TroubleEdit: 'trouble.edit',
  TroubleTransfer: 'trouble.transfer',
  TroubleAssign: 'trouble.assign',
  TroubleClose: 'trouble.close',
  TroubleCancel: 'trouble.cancel',

  //Incident
  IncidentView: 'incident.view',
  IncidentCreate: 'incident.create',
  IncidentTransfer: 'incident.transfer',
  IncidentAssign: 'incident.assign',
  IncidentClose: 'incident.close',
  IncidentCancel: 'incident.cancel',

  //Warranty
  WarrantyView: 'warranty.view',
  WarrantyCreate: 'warranty.create',
  WarrantyEdit: 'warranty.edit',
  WarrantyClose: 'warranty.close',

  //Logistic
  LogisticView: 'logistic.view',
  LogisticCreate: 'logistic.create',
  LogisticEdit: 'logistic.edit',
  LogisticClose: 'logistic.close',

  // Public: 'iam:public',
  // Authenticated: 'iam:authenticated',
  // SystemAdmin: 'crm:system.admin',

  // //Lead
  // LeadView: 'crm:lead:view',
  LeadManagement: 'crm:lead.management',

  //Deal
  // DealView: 'crm:deal:view',
  DealManagement: 'crm:deal:management',

  //Delivery
  // DeliveryView: 'crm:delivery.view',
  DeliveryManagement: 'crm:delivery.management',

  //Installation
  // InstallationView: 'crm:installation.view',
  InstallationManagement: 'crm:installation.management',

  //Trouble
  // TroubleView: 'crm:trouble.view',
  // TroubleCreate: 'crm:trouble.create',
  // TroubleEdit: 'crm:trouble.edit',
  // TroubleTransfer: 'crm:trouble.transfer',
  // TroubleAssign: 'crm:trouble.assign',
  // TroubleClose: 'crm:trouble.close',
  // TroubleCancel: 'crm:trouble.cancel',

  //Incident
  // IncidentView: 'crm:incident.view',
  IncidentManagement: 'crm:incident.management',

  //Complain
  ComplainView: 'crm:complain.view',
  ComplainOwnerView: 'crm:complain.owner.view',
  ComplainManagement: 'crm:complain.management',

  //Customer
  CustomerView: 'crm:customer.view',
  CustomerManagement: 'crm:customer.management',

  //Department
  DepartmentView: 'crm:department.view',
  DepartmentManagement: 'crm:department.management',

  //User
  SystemUserView: 'crm:system.user.view',
  SystemUserManagement: 'crm:system.user.management',

  //App user
  AppUserView: 'crm:app.user.view',
  AppUserManagement: 'crm:app.user.management',

  //Product
  // ProductView: 'crm:product.view',
  ProductManagement: 'crm:product.management',

  //SLA
  SLAView: 'crm:sla.view',
  SLAManagement: 'crm:sla.management',

  //Warranty
  // WarrantyView: 'crm:warranty.view',
  WarrantyManagement: 'crm:warranty.management',

  //MasterData
  MasterDataView: 'crm:masterdata.view',
  MasterDataManagement: 'crm:masterdata.management',

  //Permission
  PermissionView: 'crm:permission.view',
  PermissionManagement: 'crm:permission.management'
}
