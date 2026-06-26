"use strict";

import { gzip } from "pako";

export class Encoder {
  static encode(data) {
    const json = JSON.stringify(data);
    const gziped = gzip(json);
    let binary = "";
    for (const byte of gziped) binary += String.fromCharCode(byte);
    const base64 = btoa(binary);
    return encodeURIComponent(base64);
  }
}
