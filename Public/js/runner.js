"use strict";

import ReconnectingWebSocket from "reconnecting-websocket";

export class Runner {
  constructor() {
    this.connection = this.createConnection(this.endpoint());

    this.onconnect = () => {};
    this.onready = () => {};
    this.onresponse = () => {};
  }

  get isReady() {
    return this.connection.readyState === 1;
  }

  run(request) {
    const encoder = new TextEncoder();
    this.connection.send(encoder.encode(JSON.stringify(request)));
  }

  createConnection(endpoint) {
    if (
      this.connection &&
      (this.connection.readyState === 0 || this.connection.readyState === 1)
    ) {
      return this.connection;
    }

    const connection = new ReconnectingWebSocket(endpoint, [], {
      maxReconnectionDelay: 10000,
      minReconnectionDelay: 1000,
      reconnectionDelayGrowFactor: 1.3,
      connectionTimeout: 10000,
      maxRetries: Infinity,
      debug: false,
    });
    connection.bufferType = "arraybuffer";

    connection.onopen = () => {
      this.onconnect();
      this.onready();
    };

    connection.onerror = (event) => {
      connection.close();
    };

    connection.onmessage = (event) => {
      if (event.data.trim()) {
        this.onresponse(JSON.parse(event.data));
      }
    };
    return connection;
  }

  endpoint() {
    let endpoint;
    if (window.location.protocol === "https:") {
      endpoint = "wss:";
    } else {
      endpoint = "ws:";
    }
    endpoint += "//" + window.location.host;
    endpoint += window.location.pathname + "api/ws";
    return endpoint;
  }
}
