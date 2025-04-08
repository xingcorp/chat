import { Injectable } from '@nestjs/common';
import { identifyCardPlaceListSort } from "@modules/graphql/master-data/helpers/identify-card-place.master-data.helper";

@Injectable()
export class MasterDataService {
    identifyCardPlaceList() {
        const list = identifyCardPlaceListSort().map(i => ({
            title: i.name,
            value: i.name
        }));

        return {
            total: list.length,
            count: list.length,
            records: list
        }
    }
}
