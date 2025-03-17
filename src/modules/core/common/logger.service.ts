import { RequestContext } from '@common/context/request.context';

export class LoggerService {
  private serviceName: string
  constructor(serviceName: string) {
    this.serviceName = serviceName
  }

  log(message: string, ext?: any): void {
    console.log(
      `\x1b[34m${(new Date()).toISOString()} ${RequestContext.requestId()} LOG \x1b[33m${this.serviceName} \x1b[0m${message}`,
      ext ?? ''
    );
  }

  error(message: string, trace: any): void {
    console.error(`\x1b[31m${(new Date()).toISOString()} ${RequestContext.requestId()} ERROR \x1b[33m${this.serviceName} \x1b[0m${message}`, trace);
  }

  time(key: string): void {
    console.time(`PROCESSING_COUNTER ${this.serviceName}-${key}`);
  }

  timeEnd(key: string): void {
    console.timeEnd(`PROCESSING_COUNTER ${this.serviceName}-${key}`);
  }
}
