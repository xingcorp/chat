import axios from 'axios'
import Qs from 'qs'
import { BaseError, HttpError } from '../core.error'

const request = axios.create()

request.interceptors.request.use(
  (config) => {
    // if (config.url.indexOf('/token') !== -1) {
    //   delete config.headers.Authorization;
    // }
    // console.log(config)
    return config
  },
  (error) => {
    // console.log(error)
    Promise.reject(error)
  }
)

request.interceptors.response.use(
  (response) => {
    // console.log(response)
    return response
  },
  (error) => {
    // console.log(error)
    return Promise.reject(error)
  }
)

const send = (options = {}, headers = {}) => {
  return request({
    ...options,
    // paramsSerializer: (params) => Qs.stringify(params, { arrayFormat: 'repeat' }),
    headers: {
      ...headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'false'
    },
    withCredentials: false
  })
}

const sendParams = (options = {}, headers = {}, params = {}) => {
  return request({
    ...options,
    params: params,
    headers: {
      ...headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'false'
    },
    withCredentials: false
  })
}

export class RestClient {
  protected sendRawRequest = async (options = {}, headers = {}) => {
    const response = await send(options, headers)

    if (response.status != 200) {
      return { error: new BaseError(`${response.status}`, response.statusText) }
    }

    if (!response.data) {
      return { error: HttpError.NoContent }
    }

    if (response.status != 200) {
      return { error: new BaseError(`${response.status}`, response.data) }
    }

    return { response: response.data }
  }

  protected sendRequest = async (options = {}, headers = {}) => {
    const response = await send(options, headers)

    if (response.status != 200) {
      throw new BaseError(`${response.status}`, response.statusText)
    }

    if (!response.data) {
      throw HttpError.NoContent
    }

    if (response.data.code != 200) {
      throw new BaseError(`${response.data.code}`, response.data.message)
    }

    return response.data
  }

  protected sendRequestWithParams = async (
    options = {},
    headers = {},
    params = {}
  ) => {
    const response = await sendParams(options, headers, params)

    if (response.status != 200) {
      throw new BaseError(`${response.status}`, response.statusText)
    }

    // if (!response.data) {
    //     throw new BaseError("204", 'No Content')
    // }

    // if (response.data.code != 200) {
    //     throw new BaseError(`${response.data.code}`, response.data.message)
    // }

    return response.data
  }
}
