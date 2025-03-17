import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { Car } from "@models/entities/car";

@Injectable()
export class CarRepo extends Repository<Car> {
    constructor(private dataSource: DataSource) {
        super(Car, dataSource.createEntityManager());
    }

    async getById(id: any) {
        return this.findOneBy({id})
    }
}