// import { Injectable, NestMiddleware } from '@nestjs/common';
//
// @Injectable()
// export class RequestContextMiddleware implements NestMiddleware {
//   use(req: any, res: any, next: () => void) {
//     next();
//   }
// }

import { Injectable, NestMiddleware } from '@nestjs/common';
import * as cls from 'cls-hooked';
import { RequestContext } from "@common/context/request.context";


@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor() {}
  use(req, res, next) {
    const requestContext = new RequestContext(req, res);
    const session = cls.getNamespace(RequestContext.nsid) || cls.createNamespace(RequestContext.nsid);

    session.run(async () => {
      session.set(RequestContext.name, requestContext);
      next();
    })
  }
}