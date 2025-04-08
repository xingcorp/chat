import { Module } from '@nestjs/common';
import { WorkingShiftService } from './working-shift.service';
import { WorkingShiftResolver } from './working-shift.resolver';
import { TypeOrmModule } from "@nestjs/typeorm";
import {
  OfficeWorkingShift,
  OfficeWorkingShiftDetail,
  OfficeWorkingShiftOutOfTime,
  OfficeWorkingShiftOverTime
} from "@models/entities";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      OfficeWorkingShift,
      OfficeWorkingShiftDetail,
      OfficeWorkingShiftOutOfTime,
      OfficeWorkingShiftOverTime,
    ])
  ],
  providers: [WorkingShiftService, WorkingShiftResolver]
})
export class WorkingShiftModule {}
