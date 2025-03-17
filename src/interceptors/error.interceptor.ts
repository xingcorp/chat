import { BadRequestException, CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { catchError, Observable, throwError } from 'rxjs';
import { OfficeError, OfficeErrorMessage } from "@common/office.error";

@Injectable()
export class ErrorInterceptor implements NestInterceptor {
    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        return next.handle().pipe(
            catchError((err) => {
                switch (err.constructor) {
                    case BadRequestException:
                        let messageError = typeof err.response.message === 'string' ? err.response.message : err.response.message[0]
                        messageError = messageError.split('::')
                        let message = messageError.shift()

                        if (message.includes('.')) message = message.split('.').pop()
                        // console.log('m', message, messageError)

                        return throwError(() => messageError.length ? OfficeError[message](...messageError) : OfficeError[message])
                }

                return throwError(() => err)
            }),
        );
    }
}
