import { Inject, SetMetadata, forwardRef, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OfficeError } from "src/common/office.error";
import { CheckIn, CheckInPlace, WhitelistIP } from "src/models/entities";
import { OfficeUserType, RequesterId, UserIp } from "src/modules/core/middleware/decorator/user.decorator";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { CheckInHistoryFilter, CheckInPlaceArgs, CheckInPlaceFilter, EditCheckInPlaceArgs, PublicIpArgs, UserCheckInArgs, WhitelistIPFilter } from "./checkin.args";
import { CheckInPlaceResponse, CheckInResponse, WhitelistAddIpResponse, WhitelistIPResponse, WhitelistRemoveIpResponse } from "./checkin.response";
import { Between, ILike, In } from "typeorm";
import { AddressService } from "src/modules/core/iam/organization/location/address.service";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import { CheckInDetail } from "src/models/entities/checkin.detail";
import { RandomHelper } from "src/common/random";
import { StorageService } from "src/modules/core/storage/storage.service";
import { CheckinService } from "./checkin.service";
import { WhiteListIpRepo } from "@repositories/check-in/white-list.ip.repo";
import { CheckInTypeEnum } from "@enum/check-in/check-in-enum";
import { ErrorInterceptor } from "@interceptors/error.interceptor";

@Resolver()
export class CheckInResolver {
    constructor(
        @Inject(forwardRef(() => AddressService))
        private readonly addressService: AddressService,

        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        @Inject(forwardRef(() => CheckinService))
        private readonly checkinService: CheckinService,

        private readonly whiteListIpRepo: WhiteListIpRepo,
    ) { }

    @Mutation(() => WhitelistAddIpResponse, { name: 'whitelistAddIP' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async whitelistAddIP(
        @Args('publicIPs', { type: () => [PublicIpArgs] }) publicIPs: PublicIpArgs[],
        @RequesterId() requesterId: string,
    ): Promise<WhitelistAddIpResponse> {
        const existedIPs = await WhitelistIP.find({
            where: {
                publicIp: In(publicIPs.map(input => input.ip))
            }
        })
        const existedList = existedIPs.map(obj => obj.publicIp)

        const insertList: WhitelistIP[] = []
        for (const input of publicIPs) {
            if (!existedList.includes(input.ip)) {
                insertList.push(WhitelistIP.create({
                    publicIp: input.ip,
                    note: input.note,
                    createdBy: requesterId,
                    updatedBy: requesterId
                }))
            }
        }

        await WhitelistIP.save(insertList)

        return {
            total: publicIPs.length,
            existedCount: existedList.length,
            insertedCount: insertList.length,
            existedIPs: existedList,
            insertedIPs: insertList
        }
    }

    @Mutation(() => WhitelistRemoveIpResponse, { name: 'whitelistRemoveIP' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async whitelistRemoveIP(
        @Args('publicIPs', { type: () => [String] }) publicIPs: string[],
        @RequesterId() requesterId: string,
    ): Promise<WhitelistRemoveIpResponse> {
        const existedIPs = await WhitelistIP.find({
            where: {
                publicIp: In(publicIPs)
            }
        })

        await WhitelistIP.remove(existedIPs)

        return {
            total: publicIPs.length,
            removedCount: existedIPs.length,
            removedIPs: existedIPs
        }
    }

    @Query(_return => WhitelistIPResponse, { name: "whitelistGetIPs" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async whitelistGetIPs(
        @Args("filter", { nullable: true }) filter: WhitelistIPFilter
    ): Promise<WhitelistIPResponse> {
        var options: any = {}
        //skip
        if (filter && filter.page) {
            let skip = !filter.size ? 0 : filter.size * (filter.page - 1)
            skip = skip < 0 ? 0 : skip
            options.skip = skip
        } else {
            options.skip = 0
        }

        //take
        if (filter && filter.size) {
            options.take = filter.size
        } else {
            options.take = 20
        }

        let whereOptions: any = {}
        if (filter && filter.keyword) {
            whereOptions.publicIp = ILike(`%${filter.keyword}%`)
        }

        options.where = whereOptions
        options.order = {
            createdAt: "DESC"
        }
        const [list, count] = await WhitelistIP.findAndCount(options)

        return {
            total: count,
            count: list.length,
            publicIps: list
        }
    }

    @Mutation(() => CheckInPlace, { name: 'checkInAddPlace' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async checkInAddPlace(
        @Args('arguments', { nullable: false }) args: CheckInPlaceArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<CheckInPlace> {
        const existedPlace = await CheckInPlace.findOne({
            where: {
                name: args.name
            }
        })

        if (existedPlace) {
            throw OfficeError.CheckInPlaceIsExisted
        }

        const place = CheckInPlace.create({
            name: args.name,
            note: args.note,
            latitude: args.latitude,
            longitude: args.longitude,
            ipValidation: args.ipValidation,
            address: args.address,
            addressZoneId: args.addressZoneId,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        const addressZone = await this.addressService.addressZoneFindById(token, args.addressZoneId)
        if (!addressZone) throw OfficeError.AddressZoneInvalid
        var currentZone = addressZone
        while (currentZone != null) {
            switch (currentZone.level) {
                case "Province":
                    place.provinceId = currentZone.id
                    place.province = currentZone.name
                    break
                case "District":
                    place.districtId = currentZone.id
                    place.district = currentZone.name
                    break
                case "Ward":
                    place.wardId = currentZone.id
                    place.ward = currentZone.name
                    break
            }
            currentZone = currentZone.parent
        }

        return place.save()
    }

    @Mutation(() => CheckInPlace, { name: 'checkInEditPlace' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async checkInEditPlace(
        @Args('arguments', { nullable: false }) args: EditCheckInPlaceArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<CheckInPlace> {
        const existedPlace = await CheckInPlace.findOne({
            where: {
                id: args.id
            }
        })

        if (!existedPlace) {
            throw OfficeError.CheckInPlaceNotFound
        }

        // if (args.name) existedPlace.name = args.name 
        if (args.name && existedPlace.name !== args.name) {
            const checkExistedName = await CheckInPlace.findOne({
                where: {
                    name: args.name
                }
            })
            if (checkExistedName) throw OfficeError.CheckInPlaceIsExisted
            existedPlace.name = args.name
        }
        if (args.note !== undefined) existedPlace.note = args.note
        if (args.address) existedPlace.address = args.address
        if (args.ipValidation !== undefined) existedPlace.ipValidation = args.ipValidation
        if (args.latitude !== undefined) existedPlace.latitude = args.latitude
        if (args.longitude !== undefined) existedPlace.longitude = args.longitude
        if (args.addressZoneId && args.addressZoneId !== existedPlace.addressZoneId) {
            const addressZone = await this.addressService.addressZoneFindById(token, args.addressZoneId)
            if (!addressZone) throw OfficeError.AddressZoneInvalid
            existedPlace.addressZoneId = addressZone.id
            existedPlace.province = null
            existedPlace.provinceId = null
            existedPlace.district = null
            existedPlace.districtId = null
            existedPlace.ward = null
            existedPlace.wardId = null

            var currentZone = addressZone
            while (currentZone != null) {
                switch (currentZone.level) {
                    case "Province":
                        existedPlace.provinceId = currentZone.id
                        existedPlace.province = currentZone.name
                        break
                    case "District":
                        existedPlace.districtId = currentZone.id
                        existedPlace.district = currentZone.name
                        break
                    case "Ward":
                        existedPlace.wardId = currentZone.id
                        existedPlace.ward = currentZone.name
                        break
                }
                currentZone = currentZone.parent
            }
        }
        
        existedPlace.updatedBy = requesterId
        return existedPlace.save()
    }

    @Query(_return => CheckInPlace, { name: "checkInGetPlace" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async checkInGetPlace(
        @Args("id") id: string,
    ): Promise<CheckInPlace> {
        const place = await CheckInPlace.findOne({
            where: { id: id }
        })

        if (!place) throw OfficeError.CheckInPlaceNotFound

        return place
    }

    @Query(_return => CheckInPlaceResponse, { name: "checkInGetPlaceList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async checkInGetPlaceList(
        @Args("filter", { nullable: true }) filter: CheckInPlaceFilter,
        @OfficeUserType() userType: string,
    ): Promise<CheckInPlaceResponse> {
        return this.checkinService.checkInGetPlaceList(filter, userType)
    }

    @Mutation(_return => CheckInPlace, { name: "checkInRemovePlace" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async checkInRemovePlace(
        @Args("id") id: string,
        @RequesterId() requesterId: string,
    ): Promise<CheckInPlace> {
        const existedPlace = await CheckInPlace.findOne({
            where: { id: id }
        })

        if (!existedPlace) throw OfficeError.CheckInPlaceNotFound

        existedPlace.updatedBy = requesterId
        return existedPlace.softRemove()
    }

    @Mutation(() => CheckInDetail, { name: 'userCheckIn' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    async userCheckIn(
        @Args('arguments', { nullable: false }) args: UserCheckInArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
        @UserIp() userIp: string,
    ): Promise<CheckInDetail> {
        const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
        const dateArr = date.split("/")
        const checkInCode = dateArr[2] + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1]))
        
        console.log("UserID: ", requesterId, " - CHECKIN DATE: ", checkInCode, " - userIp: ", userIp)

        var existingCheckIn = await CheckIn.findOne({
            where: {
                code: checkInCode,
                createdBy: requesterId
            }
        })
        if (!existingCheckIn) {
            existingCheckIn = CheckIn.create({
                id: RandomHelper.generateUUID(),
                code: checkInCode,
                createdBy: requesterId,
                updatedBy: requesterId
            })
        }

        let checkInPlace = args?.['place']

        if (!checkInPlace) {
            checkInPlace = await CheckInPlace.findOne({
                where: {
                    id: args.placeId
                }
            })
        }

        if (!checkInPlace) throw OfficeError.CheckInPlaceNotFound

        if ((!userIp || !await this.whiteListIpRepo.isAllow(userIp)) && checkInPlace.ipValidation) {
            throw OfficeError.IpNotInWhiteList
        }

        const checkInDetail = CheckInDetail.create({
            id: RandomHelper.generateUUID(),
            checkInId: existingCheckIn.id,
            placeId: checkInPlace.id,
            checkInType: args.placeId ? CheckInTypeEnum.Place : CheckInTypeEnum.Beacon,
            // images: args.images,
            description: args.description,
            longitude: args.longitude,
            latitude: args.latitude,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (checkInDetail.imageIds) {
                    checkInDetail.imageIds.push(imageId)
                } else {
                    checkInDetail.imageIds = [imageId]
                }

                if (checkInDetail.imageUrls) {
                    checkInDetail.imageUrls.push(data.location)
                } else {
                    checkInDetail.imageUrls = [data.location]
                }
            }
        }


        await existingCheckIn.save()
        return checkInDetail.save()
    }

    @Query(() => CheckIn, { name: "checkInGetDetail" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async checkInGetDetail(
        @Args("id") id: string
    ): Promise<CheckIn> {
        const existingCheckIn = await CheckIn.findOne({
            where: {
                id: id
            }
        })
        if(!existingCheckIn) throw OfficeError.CheckInRecordNotFound

        return existingCheckIn
    }

    @Query(() => CheckInResponse, { name: "checkInGetHistories"})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async checkInGetHistories(
        @Args("filter", { nullable: true }) filter: CheckInHistoryFilter,
        @RequesterId() requesterId: string,
    ) : Promise<CheckInResponse> {
        var options: any = {}
        //skip
        if (filter && filter.page) {
            let skip = !filter.size ? 0 : filter.size * (filter.page - 1)
            skip = skip < 0 ? 0 : skip
            options.skip = skip
        } else {
            options.skip = 0
        }

        //take
        if (filter && filter.size) {
            options.take = filter.size
        } else {
            options.take = 20
        }

        var whereOptions: any = {
            createdBy: requesterId
        }

        if (filter) {
            const fromDate = filter.fromDate ? new Date(filter.fromDate) : new Date(0);
            const toDate = filter.toDate ? new Date(filter.toDate) : new Date();
            // console.log("fromDate: ", fromDate);
            // console.log("toDate: ", toDate);
            whereOptions.createdAt = Between(fromDate, toDate)
        }

        if (filter && filter.status) {
            whereOptions.status = filter.status
        }
        
        options.where = whereOptions
        // console.log("HungDN: ", options)
        const [list, count] = await CheckIn.findAndCount(options)

        return {
            total: count,
            count: list.length,
            checkIns: list
        }
    }
}