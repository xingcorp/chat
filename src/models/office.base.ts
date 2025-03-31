import { Field, Float, ObjectType } from '@nestjs/graphql'
import {
  BaseEntity,
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Generated,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  Index,
  ManyToOne
} from 'typeorm'
import { OfficeOrgChart } from './entities'

@ObjectType()
export class Base extends BaseEntity {
  @Field(() => String)
  @PrimaryGeneratedColumn('uuid')
  id: string

  @Field(() => Float, { nullable: true })
  @CreateDateColumn()
  createdAt: Date

  @Field(() => Float, { nullable: true })
  @UpdateDateColumn()
  updatedAt: Date

  @Field(() => Float, { nullable: true })
  @DeleteDateColumn()
  deletedAt: Date
}

@ObjectType()
export class OwnerBase extends Base {
  @Column({ nullable: true })
  ownerId: string

  @Index()
  @Column({ nullable: true })
  organizationId: string

  @ManyToOne(() => OfficeOrgChart)
  @Field(_type => OfficeOrgChart, { nullable: true })
  orgChart: OfficeOrgChart

  @Index()
  @Column({ nullable: true })
  orgChartId: string
}

@ObjectType()
export class OrgChartBase extends Base {
  @ManyToOne(() => OfficeOrgChart)
  @Field(_type => OfficeOrgChart, { nullable: true })
  orgChart: OfficeOrgChart

  @Index()
  @Column({ nullable: true })
  orgChartId: string
}

@ObjectType()
export class IndexBase extends BaseEntity {
  @Field(() => String, { nullable: false })
  @Column({ nullable: false, unique: true })
  @Generated('uuid')
  id: string

  @Field(() => Float, { nullable: false })
  @PrimaryGeneratedColumn()
  no: number

  @Column({ nullable: true })
  ownerId: string

  @Index()
  @Column({ nullable: true })
  organizationId: string

  @Field(() => Float, { nullable: true })
  @CreateDateColumn()
  createdAt: Date

  @Field(() => Float, { nullable: true })
  @UpdateDateColumn()
  updatedAt: Date

  @Field(() => Float, { nullable: true })
  @DeleteDateColumn()
  deletedAt: Date

  @Column({ nullable: true })
  metadata: string
}

export const NormalizePhone = (): PropertyDecorator => {
  return (target: Object, propertyKey: string) => {
    const phone = target[propertyKey]
    if (phone) {
      // target[propertyKey] = phone.replace(/\D/g, '')
    }
  }
}
