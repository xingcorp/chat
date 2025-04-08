import { Module } from '@nestjs/common';
import { FirebaseModule } from './firebase/firebase.module';
import { ObjectStoreModule } from './object-store/object-store.module';

@Module({
  imports: [FirebaseModule, ObjectStoreModule],
  providers: []
})
export class ServicesModule {}
