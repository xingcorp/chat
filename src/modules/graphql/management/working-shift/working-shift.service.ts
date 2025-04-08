import { Injectable } from '@nestjs/common';
import { WorkingShiftInput } from "@modules/graphql/management/working-shift/dto/working-shift.args";
import { InjectRepository } from "@nestjs/typeorm";
import {
    OfficeWorkingShift,
    OfficeWorkingShiftDetail,
    OfficeWorkingShiftOutOfTime,
    OfficeWorkingShiftOverTime
} from "@models/entities";
import { DataSource, Repository } from "typeorm";
import { OfficeError } from "@common/office.error";
import { isOptional } from "@utils/common.utils";

@Injectable()
export class WorkingShiftService {

    constructor(
        private dataSource: DataSource,
        @InjectRepository(OfficeWorkingShift)
        private workingShiftRepository: Repository<OfficeWorkingShift>,
        @InjectRepository(OfficeWorkingShiftDetail)
        private workingShiftDetailRepository: Repository<OfficeWorkingShiftDetail>,
        @InjectRepository(OfficeWorkingShiftOutOfTime)
        private workingShiftOutOfTimeRepository: Repository<OfficeWorkingShiftOutOfTime>,
        @InjectRepository(OfficeWorkingShiftOverTime)
        private workingShiftOverTimeRepository: Repository<OfficeWorkingShiftOverTime>,
    ) {}

    private async isShiftCodeExist(code: string) {
        return !!(await this.workingShiftRepository.findOne({
            where: {
                code
            }
        }));
    }

    async createNewShift(args: WorkingShiftInput, requesterId: string) {
        if (await this.isShiftCodeExist(args.code)) {
            throw OfficeError.EmployeeHrCodeIsExisted
        }

        const shift = this.workingShiftRepository.create({
            name: args.name,
            code: args.code,
            createdBy: requesterId
        })

        const shiftDetail = this.createNewShiftDetail(args)
        const shiftOutOfTimes = this.createNewShiftOutOfTimes(args)
        const shiftOverTimes = this.createNewShiftOverTimes(args)

        this.addCreatedById(shiftDetail, requesterId)
        this.addCreatedById(shiftOutOfTimes, requesterId)
        this.addCreatedById(shiftOverTimes, requesterId)

        shift.detail = shiftDetail
        shift.outOfTimes = shiftOutOfTimes
        shift.overTimes = shiftOverTimes

        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(shiftDetail)
            await entity.save(shiftOutOfTimes)
            await entity.save(shiftOverTimes)
            await entity.save(shift)
        })*/

        await this.dataSource.manager.save(shiftDetail)
        await this.dataSource.manager.save(shiftOutOfTimes)
        await this.dataSource.manager.save(shiftOverTimes)
        await this.dataSource.manager.save(shift)

        return shift
    }

    private createNewShiftDetail(args: WorkingShiftInput) {
        return this.workingShiftDetailRepository.create({
            startDate: args.startDate,
            endDate: args.endDate,
            dayActive: args.dayActive,
            active: args.active,
            noCheckInTimePunishment: args.noCheckInTimePunishment,
            noCheckOutTimePunishment: args.noCheckOutTimePunishment,
            checkInTime: args.checkInTime,
            checkOutTime: args.checkOutTime,
            lunchStartTime: isOptional(args.lunchStartTime),
            lunchEndTime: isOptional(args.lunchEndTime),
        })
    }

    private createNewShiftOutOfTimes(args: WorkingShiftInput) {
        let res = []
        if (args.outOfTime) {
            for (const item of args.outOfTime) {
                res.push(this.workingShiftOutOfTimeRepository.create({
                    type: item.type,
                    from: item.from,
                    to: item.to,
                    punishmentType: item.punishmentType,
                    punishmentValue: isOptional(item.punishmentValue),
                }))
            }
        }

        return res
    }

    private createNewShiftOverTimes(args: WorkingShiftInput) {
        let res = []
        if (args.overTime) {
            for (const item of args.overTime) {
                res.push(this.workingShiftOverTimeRepository.create({
                    type: item.type,
                    minTime: isOptional(item.minTime, 0),
                    maxTime: isOptional(item.maxTime),
                    startTime: isOptional(item.startTime),
                    isStartAfterEndShift: isOptional(item.isStartAfterEndShift, false)
                }))
            }
        }

        return res
    }

    private addCreatedById(data: any, requesterId: string) {
        data.createdBy = requesterId
    }
}
