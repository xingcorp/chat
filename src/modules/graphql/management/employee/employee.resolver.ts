import { forwardRef, Inject, ParseArrayPipe, SetMetadata, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OfficeError } from "src/common/office.error";
import { InfoField, OfficeUser, UserSchedule } from "src/models/entities";
import { IdentityService } from "src/modules/core/iam/identity/identity.service";
import { AddressService } from "src/modules/core/iam/organization/location/address.service";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { StorageService } from "src/modules/core/storage/storage.service";
import { Between, DataSource } from "typeorm";
import {
    AddEmployeeArgs, AnalysisNumberOfUserUsedAppFilter,
    EditEmployeeArgs, EmployeeBulkCreateImport,
    EmployeeReportFilterArgs,
    ImportEmployeeArgs, OfficeEmployeeAvatarUpdateInput,
    OfficeUserFilter,
    QueryScheduleArgs,
    UpsertEmployeeDataArgs
} from "./employee.args";
import {
    AnalysisNumberOfUserUsedAppResponse,
    BulkImportEmployeeResponse,
    BulkUpsertEmployeeDataResponse, EmployeeBulkCreateResponse,
    ImportUserFieldsGetResponse,
    OfficeUserResponse,
    SchedulesResponse,
    UpsertEmployeeDataResponse
} from "./employee.response";
import { validatePhoneNumber, validateDateFormat, validateEmail, validateNumeric } from "@common/regex";
import { DataType } from "src/models/entities/profile.info.field";
import {
    IsSystemOfficeAdmin,
    OfficeRequesterId,
    RequesterId
} from "src/modules/core/middleware/decorator/user.decorator";
import { File } from "src/modules/core/storage/objects/file";
import { EmployeeService } from "./employee.service";
import { dayMonthYearToTime } from "@utils/datetime.utils";
import { removeUndefinedValue } from "@utils/object.utils";
import {
    FixedDataOrgChartUserAllAndWithChildInterceptor,
    FixedDataOrgChartUserAllInterceptor
} from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { ValidateDataTypeBulkUpsertInterceptor } from "@interceptors/validate-data-type.interceptor";
import { FieldsListResponse } from "@models/base/index.response";

@Resolver()
export class EmployeeResolver {
    constructor(
        @Inject(forwardRef(() => IdentityService))
        private readonly identityService: IdentityService,

        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        @Inject(forwardRef(() => AddressService))
        private readonly addressService: AddressService,

        @Inject(forwardRef(() => EmployeeService))
        private readonly employeeService: EmployeeService,
        private dataSource: DataSource,
    ) { }

    @Mutation(() => OfficeUser, { name: 'managementAddEmployee', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementAddEmployee(
        @Args('arguments', { nullable: false }) args: AddEmployeeArgs,
    ): Promise<OfficeUser> {
        return this.employeeService.managementAddEmployee(args)
    }

    @Query(_return => OfficeUser, { name: "managementGetEmployee" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async managementGetEmployee(
        @Args("id") id: string,
    ): Promise<OfficeUser> {
        console.log('id', id)
        const employee = await OfficeUser.findOne({
            where: { id: id }
        })

        if (!employee) throw OfficeError.EmployeeNotFound

        return employee
    }

    @Query(() => OfficeUserResponse, { name: 'managementGetEmployeeList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementGetEmployeeList(
        @BearerAccessToken() token: string,
        @Args("filter", { nullable: true }) filter: OfficeUserFilter,
        @RequesterId() requesterId: string,
    ): Promise<OfficeUserResponse> {
        return this.employeeService.managementGetEmployeeList(token, filter, requesterId)
    }

    @Mutation(_return => OfficeUser, { name: "managementEditEmployee" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementEditEmployee(
        @Args('arguments', { nullable: false }) args: EditEmployeeArgs,
    ): Promise<OfficeUser> {
        return this.employeeService.managementEditEmployee(args)
    }

   /* // @Mutation(_type => BulkUpsertEmployeeResponse, { nullable: true, name: "managementEmployeeBulkUpsert" })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    // async managementEmployeeBulkUpsert(
    //     @Args('officeUsers', { type: () => [UpsertEmployeeArgs] }) officeUsers: UpsertEmployeeArgs[],
    //     @BearerAccessToken() token: string,
    //     @RequesterId() requesterId: string,
    // ): Promise<BulkUpsertEmployeeResponse> {
    //     try {
    //         const response: UpsertEmployeeResponse[] = []
    //         const existedEmpCodes: String[] = []
    //         const upsertEmployees: OfficeUser[] = []
    //         const departmentDict: any = {}
    //         const titleDict: any = {}
    //         const removeUserDepartments: UserDepartment[] = []
    //         const upsertUserDepartments: UserDepartment[] = []
    //         const upsertUserBankAccounts: UserBankAccount[] = []
    //         const upsertUserAddresses: UserAddress[] = []
    //         for (const input of officeUsers) {
    //             if (!input.code || !input.fullname || !input.phone || !input.departments || !input.status) {
    //                 response.push({ ...input, errorMessage: 'Vui lòng không để trống trường bắt buộc' })
    //                 continue
    //             }

    //             if (!Object.keys(ObjectStatus).includes(input.status)) {
    //                 response.push({ ...input, errorMessage: 'Vui lòng nhập giá trị là Active hoặc Inactive' })
    //                 continue
    //             }

    //             const existedEmployeeCode = await OfficeUser.findOne({
    //                 where: {
    //                     code: input.code
    //                 }
    //             })

    //             if (input.id) {
    //                 // update
    //                 const existedEmployee = await OfficeUser.findOne({
    //                     where: { id: input.id }
    //                 })

    //                 if (!existedEmployee) {
    //                     response.push({ ...input, errorMessage: 'Không tìm thấy thông tin nhân viên' })
    //                     continue
    //                 }

    //                 if ((existedEmployeeCode && existedEmployeeCode.code !== existedEmployee.code) || existedEmpCodes.includes(input.code)) {
    //                     response.push({ ...input, errorMessage: 'Mã nhân viên đã tồn tại trên hệ thống' })
    //                     continue
    //                 }

    //                 //department & title
    //                 const unrecognizeDepartments = []
    //                 const unrecognizeTitles = []
    //                 const departments = input.departments.split(",")
    //                 const newUserDepartments: UserDepartment[] = []
    //                 for (const departmentInput of departments) {
    //                     const departmentArr = departmentInput.split("::")
    //                     const department = departmentArr.length > 0 ? departmentArr[0] : null
    //                     const title = departmentArr.length > 1 ? departmentArr[1] : null
    //                     if (department) {
    //                         var departmentEntity = departmentDict[department]
    //                         if (!departmentEntity) {
    //                             departmentEntity = await OfficeOrgChart.findOne({
    //                                 where: { code: department }
    //                             })

    //                             if (!departmentEntity) {
    //                                 unrecognizeDepartments.push(department)
    //                             } else {
    //                                 departmentDict[department] = departmentEntity
    //                             }
    //                         }

    //                         if (departmentEntity) {
    //                             const userDepartment = UserDepartment.create({
    //                                 departmentId: departmentEntity.id,
    //                                 userId: existedEmployee.id
    //                             })

    //                             if (title) {
    //                                 var titleEntity = titleDict[title]
    //                                 if (!titleEntity) {
    //                                     titleEntity = await OfficeTitle.findOne({
    //                                         where: { code: title }
    //                                     })
    //                                 }

    //                                 if (titleEntity) {
    //                                     titleDict[title] = titleEntity
    //                                     userDepartment.titleId = titleEntity.id
    //                                 } else {
    //                                     unrecognizeTitles.push(title)
    //                                 }
    //                             }

    //                             newUserDepartments.push(userDepartment)
    //                         }
    //                     }
    //                 }

    //                 if (unrecognizeDepartments.length > 0) {
    //                     var departmentStr = ''
    //                     unrecognizeDepartments.forEach((value, index) => {
    //                         if (index < unrecognizeDepartments.length - 1) {
    //                             departmentStr += `${value}, `
    //                         } else {
    //                             departmentStr += `${value}`
    //                         }
    //                     })
    //                     response.push({ ...input, errorMessage: `Mã phòng ban ${departmentStr} chưa tồn tại trên hệ thống` })
    //                     continue
    //                 }

    //                 if (unrecognizeTitles.length > 0) {
    //                     var titleStr = ''
    //                     unrecognizeTitles.forEach((value, index) => {
    //                         if (index < unrecognizeTitles.length - 1) {
    //                             titleStr += `${value}, `
    //                         } else {
    //                             titleStr += `${value}`
    //                         }
    //                     })
    //                     response.push({ ...input, errorMessage: `Mã chức vụ ${titleStr} chưa tồn tại trên hệ thống` })
    //                     continue
    //                 }

    //                 const existedUserDepartments = await UserDepartment.find({
    //                     where: {
    //                         userId: existedEmployee.id
    //                     }
    //                 })
    //                 existedUserDepartments.forEach(ud => {
    //                     removeUserDepartments.push(ud)
    //                 })
    //                 newUserDepartments.forEach(nud => {
    //                     upsertUserDepartments.push(nud)
    //                 })

    //                 existedEmployee.code = input.code
    //                 existedEmployee.fullname = input.fullname
    //                 existedEmployee.email = input.email
    //                 //address & addressZoneId & bank
    //                 var userBankAccount = await UserBankAccount.findOne({
    //                     where: { userId: existedEmployee.id }
    //                 })
    //                 if (userBankAccount) {
    //                     userBankAccount.bankBranch = input.bankBranch
    //                     userBankAccount.accountHolder = input.accountHolder
    //                     userBankAccount.accountNumber = input.accountNumber
    //                     if (userBankAccount.bankName !== input.bankName) {
    //                         userBankAccount.bankId = null
    //                         userBankAccount.bankName = null
    //                         if (input.bankName) {
    //                             const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
    //                             userBankAccount.bankId = data?.id
    //                             userBankAccount.bankName = data?.brandName
    //                         }
    //                     }
    //                 } else {
    //                     if (input.bankBranch || input.accountHolder || input.accountNumber) {
    //                         userBankAccount = UserBankAccount.create({
    //                             accountHolder: input.accountHolder,
    //                             accountNumber: input.accountNumber,
    //                             bankBranch: input.bankBranch,
    //                             userId: existedEmployee.id
    //                         })
    //                     }

    //                     if (input.bankName) {
    //                         const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
    //                         if (data) {
    //                             if (userBankAccount) {
    //                                 userBankAccount.bankId = data.id
    //                                 userBankAccount.bankName = data.brandName
    //                             } else {
    //                                 userBankAccount = UserBankAccount.create({
    //                                     bankId: data.id,
    //                                     bankName: data.brandName,
    //                                     userId: existedEmployee.id
    //                                 })
    //                             }
    //                         }
    //                     }
    //                 }
    //                 if (userBankAccount) upsertUserBankAccounts.push(userBankAccount)

    //                 var userAddress = await UserAddress.findOne({
    //                     where: { userId: existedEmployee.id }
    //                 })
    //                 if (userAddress) {
    //                     userAddress.address = input.address
    //                     userAddress.addressZoneId = null
    //                     userAddress.provinceId = null
    //                     userAddress.province = null
    //                     userAddress.districtId = null
    //                     userAddress.district = null
    //                     userAddress.wardId = null
    //                     userAddress.ward = null
    //                     const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
    //                         province: input.province,
    //                         district: input.district,
    //                         ward: input.ward
    //                     })
    //                     if (addressZone) {
    //                         userAddress.addressZoneId = addressZone.id
    //                         var currentZone = addressZone
    //                         while (currentZone != null) {
    //                             switch (currentZone.level) {
    //                                 case "Province":
    //                                     userAddress.provinceId = currentZone.id
    //                                     userAddress.province = currentZone.name
    //                                     break
    //                                 case "District":
    //                                     userAddress.districtId = currentZone.id
    //                                     userAddress.district = currentZone.name
    //                                     break
    //                                 case "Ward":
    //                                     userAddress.wardId = currentZone.id
    //                                     userAddress.ward = currentZone.name
    //                                     break
    //                             }
    //                             currentZone = currentZone.parent
    //                         }
    //                     }
    //                 } else {
    //                     const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
    //                         province: input.province,
    //                         district: input.district,
    //                         ward: input.ward
    //                     })
    //                     if (input.address || addressZone) {
    //                         userAddress = UserAddress.create({
    //                             address: input.address,
    //                             userId: existedEmployee.id
    //                         })
    //                         userAddress.addressZoneId = addressZone.id
    //                         var currentZone = addressZone
    //                         while (currentZone != null) {
    //                             switch (currentZone.level) {
    //                                 case "Province":
    //                                     userAddress.provinceId = currentZone.id
    //                                     userAddress.province = currentZone.name
    //                                     break
    //                                 case "District":
    //                                     userAddress.districtId = currentZone.id
    //                                     userAddress.district = currentZone.name
    //                                     break
    //                                 case "Ward":
    //                                     userAddress.wardId = currentZone.id
    //                                     userAddress.ward = currentZone.name
    //                                     break
    //                             }
    //                             currentZone = currentZone.parent
    //                         }
    //                     }
    //                 }
    //                 if (userAddress) upsertUserAddresses.push(userAddress)

    //                 existedEmployee.status = ObjectStatus[input.status]
    //                 existedEmployee.updatedBy = requesterId
    //                 upsertEmployees.push(existedEmployee)
    //                 response.push({ ...input, errorMessage: 'Cập nhật thành công' })
    //             } else {
    //                 // insert
    //                 if (existedEmployeeCode || existedEmpCodes.includes(input.code)) {
    //                     response.push({ ...input, errorMessage: 'Mã nhân viên đã tồn tại trên hệ thống' })
    //                     continue
    //                 }

    //                 if (!validatePhoneNumber(input.phone)) {
    //                     response.push({ ...input, errorMessage: 'Số điện thoại không đúng định dạng' })
    //                     continue
    //                 }

    //                 const checkPhone = await OfficeUser.findOne({
    //                     where: {
    //                         phone: input.phone
    //                     }
    //                 })
    //                 if (checkPhone) {
    //                     response.push({ ...input, errorMessage: 'Số điện thoại đã tồn tại trên hệ thống' })
    //                     continue
    //                 }

    //                 const officeUser = OfficeUser.create({
    //                     id: RandomHelper.generateUUID(),
    //                     fullname: input.fullname,
    //                     code: input.code,
    //                     phone: input.phone,
    //                     email: input.email,
    //                     status: ObjectStatus[input.status],
    //                     createdBy: requesterId,
    //                     updatedBy: requesterId,
    //                     // iamUserId: data.id,
    //                     // note: input.note,
    //                     // metadata: [JSON.stringify(args.data)]
    //                 })

    //                 //department & title
    //                 const unrecognizeDepartments = []
    //                 const departments = input.departments.split(",")
    //                 const newUserDepartments: UserDepartment[] = []
    //                 for (const departmentInput of departments) {
    //                     const departmentArr = departmentInput.split("::")
    //                     const department = departmentArr.length > 0 ? departmentArr[0] : null
    //                     const title = departmentArr.length > 1 ? departmentArr[1] : null
    //                     if (department) {
    //                         var departmentEntity = departmentDict[department]
    //                         if (!departmentEntity) {
    //                             departmentEntity = await OfficeOrgChart.findOne({
    //                                 where: { code: department }
    //                             })

    //                             if (!departmentEntity) {
    //                                 unrecognizeDepartments.push(department)
    //                             } else {
    //                                 departmentDict[department] = departmentEntity
    //                             }
    //                         }

    //                         if (departmentEntity) {
    //                             const userDepartment = UserDepartment.create({
    //                                 departmentId: departmentEntity.id,
    //                                 userId: officeUser.id
    //                             })

    //                             if (title) {
    //                                 var titleEntity = titleDict[title]
    //                                 if (!titleEntity) {
    //                                     titleEntity = await OfficeTitle.findOne({
    //                                         where: { code: title }
    //                                     })
    //                                 }

    //                                 if (titleEntity) {
    //                                     titleDict[title] = titleEntity
    //                                     userDepartment.titleId = titleEntity.id
    //                                 }
    //                             }

    //                             newUserDepartments.push(userDepartment)
    //                         }
    //                     }
    //                 }

    //                 if (unrecognizeDepartments.length > 0) {
    //                     var departmentStr = ''
    //                     unrecognizeDepartments.forEach((value, index) => {
    //                         if (index < unrecognizeDepartments.length - 1) {
    //                             departmentStr += `${value}, `
    //                         } else {
    //                             departmentStr += `${value}`
    //                         }
    //                     })
    //                     response.push({ ...input, errorMessage: `Mã phòng ban ${departmentStr} chưa tồn tại trên hệ thống` })
    //                     continue
    //                 }

    //                 const { data, error } = await this.identityService.userCreate(
    //                     token,
    //                     input.fullname,
    //                     input.email,
    //                     input.phone
    //                 )
    //                 if (error) {
    //                     response.push({ ...input, errorMessage: `Lỗi hệ thống` })
    //                     continue
    //                 }
    //                 officeUser.iamUserId = data.id

    //                 var newUserBankAccount = null
    //                 if (input.bankBranch || input.accountHolder || input.accountNumber) {
    //                     newUserBankAccount = UserBankAccount.create({
    //                         accountHolder: input.accountHolder,
    //                         accountNumber: input.accountNumber,
    //                         bankBranch: input.bankBranch,
    //                         userId: officeUser.id
    //                     })
    //                 }
    //                 if (input.bankName) {
    //                     const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
    //                     if (data) {
    //                         if (newUserBankAccount) {
    //                             newUserBankAccount.bankId = data.id
    //                             newUserBankAccount.bankName = data.brandName
    //                         } else {
    //                             newUserBankAccount = UserBankAccount.create({
    //                                 bankId: data.id,
    //                                 bankName: data.brandName,
    //                                 userId: officeUser.id
    //                             })
    //                         }
    //                     }
    //                 }
    //                 if (newUserBankAccount) upsertUserBankAccounts.push(newUserBankAccount)

    //                 const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
    //                     province: input.province,
    //                     district: input.district,
    //                     ward: input.ward
    //                 })
    //                 if (input.address || addressZone) {
    //                     userAddress = UserAddress.create({
    //                         address: input.address,
    //                         userId: officeUser.id
    //                     })
    //                     userAddress.addressZoneId = addressZone.id
    //                     var currentZone = addressZone
    //                     while (currentZone != null) {
    //                         switch (currentZone.level) {
    //                             case "Province":
    //                                 userAddress.provinceId = currentZone.id
    //                                 userAddress.province = currentZone.name
    //                                 break
    //                             case "District":
    //                                 userAddress.districtId = currentZone.id
    //                                 userAddress.district = currentZone.name
    //                                 break
    //                             case "Ward":
    //                                 userAddress.wardId = currentZone.id
    //                                 userAddress.ward = currentZone.name
    //                                 break
    //                         }
    //                         currentZone = currentZone.parent
    //                     }
    //                 }
    //                 if (userAddress) upsertUserAddresses.push(userAddress)

    //                 newUserDepartments.forEach(nud => {
    //                     upsertUserDepartments.push(nud)
    //                 })

    //                 upsertEmployees.push(officeUser)
    //                 response.push({ ...input, errorMessage: 'Tạo mới thành công' })
    //                 existedEmpCodes.push(input.code)
    //             }
    //         }

    //         // for (const iterator of upsertEmployees) {
    //         //     await iterator.save()
    //         // }
    //         await UserDepartment.remove(removeUserDepartments)
    //         await UserDepartment.save(upsertUserDepartments)
    //         await UserBankAccount.save(upsertUserBankAccounts)
    //         await UserAddress.save(upsertUserAddresses)
    //         await OfficeUser.save(upsertEmployees)

    //         return {
    //             total: response.length,
    //             count: response.length,
    //             records: response
    //         }
    //     } catch (error) {
    //         console.log(`Bulk upsert employee has error: ${error}`)
    //         throw error
    //     }
    // }*/

    @Mutation(_type => BulkUpsertEmployeeDataResponse, { nullable: true, name: "managementEmployeeDataBulkUpsert" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementEmployeeDataBulkUpsert(
        @Args('employeeDatas', { type: () => [UpsertEmployeeDataArgs] }) employeeDatas: UpsertEmployeeDataArgs[],
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<BulkUpsertEmployeeDataResponse> {
        try {
            const response: UpsertEmployeeDataResponse[] = []
            const upsertEmployees: OfficeUser[] = []
            const fields = await InfoField.find({
                where: {},
                order: {
                    no: "ASC"
                }
            })
            const listFieldRequired = await this.employeeService.getListFieldRequiredAtImport(employeeDatas.length ? employeeDatas[0]?.data : {})
            for (const input of employeeDatas) {
                var errorMessage = ""
                if (!input.code || listFieldRequired.filter(i => !Object.keys(input.data).includes(i)).length) {
                    errorMessage = 'Vui lòng không để trống trường bắt buộc'
                }

                const officeUser = await OfficeUser.findOne({
                    where: {
                        code: input.code
                    }
                })
                if (!officeUser) errorMessage = 'Mã nhân viên không tồn tại trên hệ thống'

                const filterData: any = {}
                const responseData: any = {}
                fields.forEach(f => {
                    if (!errorMessage) {
                        /* https://jr.smarthiz.vn/browse/SOF-693 */
                        // if (!input.data[f.code] && f.required) {
                        //     errorMessage = 'Vui lòng không để trống trường bắt buộc'
                        // }
                        if (f.dataType === DataType.Date && input.data[f.code] && !validateDateFormat(input.data[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.List && input.data[f.code] && !f.optionItems.map(i => i.trim()).includes(input.data[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.Email && input.data[f.code] && !validateEmail(input.data[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.Number_Limit_Length_10 && input.data[f.code] && !validatePhoneNumber(input.data[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.Number && input.data[f.code] && !validateNumeric(input.data[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                    }

                    responseData[f.code] = input.data[f.code]
                    if (f.dataType === DataType.Date && input.data[f.code] && validateDateFormat(input.data[f.code])) {
                        filterData[f.code] = dayMonthYearToTime(input.data[f.code])
                    } else {
                        filterData[f.code] = input.data[f.code]
                    }

                })

                if (errorMessage) {
                    response.push({ code: input.code, data: responseData, errorMessage: errorMessage })
                } else {
                    try {
                        officeUser.metadata = [JSON.stringify({ ...JSON.parse(officeUser.metadata[0]), ...removeUndefinedValue(filterData) })]
                    } catch {
                        officeUser.metadata = [JSON.stringify(filterData)]
                    }
                    officeUser.updatedBy = requesterId
                    upsertEmployees.push(officeUser)
                    response.push({ code: input.code, data: responseData, errorMessage: "Cập nhật thành công" })
                }
            }

            await OfficeUser.save(upsertEmployees)

            return {
                total: response.length,
                count: response.length,
                records: response
            }
        } catch (error) {
            console.log(`Bulk upsert employee data has error: ${error}`)
            throw error
        }
    }

    @Query(_return => SchedulesResponse, { name: "managementGetEmployeeSchedule" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async managementGetEmployeeSchedule(
        @Args("arguments") filter: QueryScheduleArgs,
        @OfficeRequesterId() officeRequesterId: string,
    ): Promise<SchedulesResponse> {
        const [schedules, total] = await UserSchedule.createQueryBuilder('schedule')
            .where({
                startAt: Between(new Date(filter.startAt), new Date(filter.endAt)),
                ownerId: officeRequesterId
            })
            .leftJoinAndSelect('schedule.meeting', 'meeting')
            .getManyAndCount()

        return {
            total,
            count: schedules.length,
            schedules
        }
    }

    @Mutation(_type => BulkImportEmployeeResponse, { nullable: true, name: "managementEmployeeBulkUpsert" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ValidateDataTypeBulkUpsertInterceptor)
    async managementEmployeeBulkUpsertNew(
        @Args(
            'officeUsers',
            {type: () => [ImportEmployeeArgs]},
            new ParseArrayPipe({items: ImportEmployeeArgs})
        ) officeUsers: ImportEmployeeArgs[],
    ): Promise<BulkImportEmployeeResponse> {
        return this.employeeService.managementEmployeeBulkUpsertBasicData(officeUsers)
    }

    @Mutation(_type => EmployeeBulkCreateResponse, { nullable: true, name: "managementEmployeeBulkCreate" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ValidateDataTypeBulkUpsertInterceptor)
    async managementEmployeeBulkCreate(
        @Args(
            'officeUsers',
            {type: () => [EmployeeBulkCreateImport]},
            new ParseArrayPipe({items: EmployeeBulkCreateImport})
        ) officeUsers: EmployeeBulkCreateImport[],
    ): Promise<EmployeeBulkCreateResponse> {
        return this.employeeService.managementEmployeeBulkCreate(officeUsers)
    }

    /*@Mutation(_type => BulkImportEmployeeResponse, { nullable: true, name: "managementEmployeeBulkUpsertWithoutSomeRequired" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementEmployeeBulkUpsertWithoutSomeRequired(
        @Args('officeUsers', { type: () => [ImportEmployeeArgs] }) officeUsers: ImportEmployeeArgs[],
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<BulkImportEmployeeResponse> {
        return this.employeeService.managementEmployeeBulkUpsert(officeUsers, token, requesterId, false)
    }*/

    @Query(() => File, { name: 'managementEmployeeReportSummaryExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async employeeReportSummaryExport(
        @BearerAccessToken() token: string,
        @Args("filter", { nullable: true }) filter: EmployeeReportFilterArgs,
        @RequesterId() requesterId: string,
    ): Promise<File> {
        return this.employeeService.employeeReportSummaryExport(token, filter, requesterId)
    }

    @Query(() => File, { name: 'managementEmployeeResignReportExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async employeeResignReportExport(
        @BearerAccessToken() token: string,
        @Args("filter", { nullable: true }) filter: EmployeeReportFilterArgs,
        @RequesterId() requesterId: string,
    ): Promise<File> {
        return this.employeeService.employeeResignReportExport(token, filter, requesterId)
    }

    @Query(() => File, { name: 'managementEmployeeReportDetailExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async employeeReportDetailExport(
        @BearerAccessToken() token: string,
        @Args("filter", { nullable: true }) filter: EmployeeReportFilterArgs,
        @RequesterId() requesterId: string,
    ): Promise<File> {
        return this.employeeService.employeeReportDetailExport(token, filter, requesterId)
    }

    /*TODO: Remove to analysis module when have more analysis function*/
    @Query(() => AnalysisNumberOfUserUsedAppResponse, { name: 'analysisNumberOfUserUsedApp', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async analysisNumberOfUserUsedApp(
        @Args("filter", { nullable: true }) args: AnalysisNumberOfUserUsedAppFilter,
        @IsSystemOfficeAdmin() isSysOfficeAdmin: boolean,
    ): Promise<AnalysisNumberOfUserUsedAppResponse> {
        return this.employeeService.analysisNumberOfUserUsedApp(isSysOfficeAdmin, args)
    }

    @Query(() => File, { name: 'managementImportUserTemplateExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserTemplateExport(): Promise<File> {
        return this.employeeService.importUserTemplateExport()
    }

    @Query(() => ImportUserFieldsGetResponse, { name: 'managementImportUserFieldsGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserFieldsGet(): Promise<ImportUserFieldsGetResponse> {
        return this.employeeService.importUserFieldsGet()
    }

    @Query(() => ImportUserFieldsGetResponse, { name: 'managementImportUserFieldsGetTitle', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserFieldsGetTitle(): Promise<ImportUserFieldsGetResponse> {
        return this.employeeService.importUserFieldsGetTitle()
    }

    @Mutation(_return => File, { name: "officeEmployeeAvatarUpdate" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeEmployeeAvatarUpdate(
        @Args('arguments', { nullable: false }) args: OfficeEmployeeAvatarUpdateInput,
    ): Promise<File> {
        return this.employeeService.officeEmployeeAvatarUpdate(args)
    }

    @Query(() => File, { name: 'managementImportUserCreateTemplateExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserCreateTemplateExport(): Promise<File> {
        return this.employeeService.importUserCreateTemplateExport()
    }

    @Query(() => FieldsListResponse, { name: 'managementImportUserCreateFieldsGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserCreateFieldsGet(): Promise<FieldsListResponse> {
        return this.employeeService.importUserCreateFieldsGet()
    }

    @Query(() => FieldsListResponse, { name: 'managementImportUserCreateFieldsGetTitle', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportUserCreateFieldsGetTitle(): Promise<FieldsListResponse> {
        return this.employeeService.importUserCreateFieldsGetTitle()
    }
}