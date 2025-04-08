import { forwardRef, Module } from '@nestjs/common';
import { ChatNotifyService } from './chat-notify.service';
import { ChatNotifyResolver } from './chat-notify.resolver';
import { IAMModule } from "@core/iam/iam.module";

@Module({
  imports: [
    forwardRef(() => IAMModule),
  ],
  providers: [ChatNotifyService, ChatNotifyResolver],
  exports: [ChatNotifyService]
})
export class ChatNotifyModule { }
