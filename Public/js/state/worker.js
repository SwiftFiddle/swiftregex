"use strict";

import { Decoder } from "./decoder.js";
import { Encoder } from "./encoder.js";

onmessage = (e) => {
  if (!e.data || !e.data.type || !e.data.value) {
    return;
  }
  switch (e.data.type) {
    case "decode": {
      const searchParams = new URLSearchParams(e.data.value);
      const query = Object.fromEntries(searchParams.entries());
      if (!query.s) {
        return;
      }
      try {
        const data = Decoder.decode(query.s);
        if (!data) {
          return;
        }

        const pattern = data.p;
        const options = data.o;
        const text1 = data.t1;
        const builder = data.b;
        const text2 = data.t2;
        postMessage({
          type: e.data.type,
          value: {
            pattern,
            options,
            text1,
            builder,
            text2,
          },
        });
      } catch (error) {}
      break;
    }
    case "encode": {
      postMessage({
        type: e.data.type,
        value: `?s=${Encoder.encode({
          p: e.data.value.pattern,
          o: e.data.value.options,
          t1: e.data.value.text1,
          b: e.data.value.builder,
          t2: e.data.value.text2,
        })}`,
      });
      break;
    }
  }
};
