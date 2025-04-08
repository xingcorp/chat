// import { DataSource, EntitySubscriberInterface, EventSubscriber, InsertEvent } from "typeorm";
// import { InfoBlock } from "./profile.info.block";

// @EventSubscriber()
// export class InfoBlockSubscriber implements EntitySubscriberInterface<InfoBlock> {
//   constructor(dataSource: DataSource) {
//     dataSource.subscribers.push(this);
//   }

//   listenTo() {
//     return InfoBlock;
//   }

//   afterInsert(event: InsertEvent<InfoBlock>) {
//     // console.log(`AFTER USER INSERTED: `, event.entity);
//     const repo = event.manager.connection.getRepository(InfoBlock);
//     event.entity.code = `block_${event.entity.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${event.entity.no}`;
//     repo.save(event.entity);
//   }
// }