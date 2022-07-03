"use strict";

import { Runner } from "./runner";
import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";

class WASICommand {
  constructor(wasmModule) {
    this.wasmModule = wasmModule;
  }

  static async load(wasmFile) {
    const response = await fetch(wasmFile)
    if (WebAssembly.compileStreaming) {
      const wasmModule = await WebAssembly.compileStreaming(response);
      return new WASICommand(wasmModule);
    } else {
      const bytes = await response.arrayBuffer();
      const wasmModule = await WebAssembly.compile(bytes);
      return new WASICommand(wasmModule);
    }
  }

  async exec(args) {
    const wasmFs = new WasmFs();
    let stdout = "";
    let stderr = "";
    const originalWriteSync = wasmFs.fs.writeSync;
    wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
      const text = new TextDecoder("utf-8").decode(buffer);
      switch (fd) {
        case 1:
          stdout += text;
          break;
        case 2:
          stderr += text;
          console.error(text);
          break;
      }
      return originalWriteSync(fd, buffer, offset, length, position);
    };

    const wrapWASI = (wasiObject) => {
      // PATCH: @wasmer-js/wasi@0.x forgets to call `refreshMemory` in `clock_res_get`,
      // See also https://github.com/swiftwasm/carton/blob/2c5cf34e0cbb6a4807445ef62a8404bac40314b1/entrypoint/common.js#L135-L145
      const original_clock_res_get = wasiObject.wasiImport["clock_res_get"];

      wasiObject.wasiImport["clock_res_get"] = (clockId, resolution) => {
        wasiObject.refreshMemory();
        return original_clock_res_get(clockId, resolution);
      };
      return wasiObject.wasiImport;
    };
    const wasi = new WASI({
      args: ["main.wasm", ...args],
      bindings: {
        ...WASI.defaultBindings,
        fs: wasmFs.fs,
      },
    });
    const instance = await WebAssembly.instantiate(this.wasmModule, {
      wasi_snapshot_preview1: wrapWASI(wasi),
    });
    wasi.start(instance);
    return { stdout, stderr };
  }
}

export class WasmRunner extends Runner {
  constructor() {
    super();

    this.locallyAvailableMethods = {
      "parseDSL": {
        command: WASICommand.load("./DSLParser.wasm"),
        async run(request, command) {
          const { stdout, stderr } =  await command.exec([request.pattern])
          return { method: request.method, result: stdout, error: stderr };
        }
      },
      "convertToDSL": {
        command: WASICommand.load("./DSLConverter.wasm"),
        async run(request, command) {
          const { stdout, stderr } =  await command.exec([request.pattern])
          return { method: request.method, result: stdout, error: stderr };
        }
      },
      "match": {
        command: WASICommand.load("./Matcher.wasm"),
        async run(request, command) {
          const { stdout, stderr } =  await command.exec([request.pattern, request.text, request.matchOptions.join(",")])
          return { method: request.method, result: stdout, error: stderr };
        }
      },
      "parseExpression": {
        command: WASICommand.load("./ExpressionParser.wasm"),
        async run(request, command) {
          const { stdout, stderr } =  await command.exec([request.pattern, request.matchOptions.join(",")])
          return { method: request.method, result: stdout, error: stderr };
        }
      },
    }
  }
  async run(request) {
    if (this.locallyAvailableMethods[request.method]) {
      try {
        const method = this.locallyAvailableMethods[request.method];
        const command = await method.command;
        const response = await method.run(request, command);
        console.log(response);
        this.onresponse(response);
      } catch (e) {
        console.warn(`Error while running ${request.method} on local. Retry on backend:`, e);
        super.run(request);
      }
      return;
    }
    super.run(request);
  }
}
