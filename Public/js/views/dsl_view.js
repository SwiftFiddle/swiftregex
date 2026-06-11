"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";
import ErrorMessage from "./error_message";

export class DSLView extends EventDispatcher {
  constructor(container) {
    super();
    this.container = container;
    this.init(container);
  }

  get value() {
    return this.view.state.doc.toString();
  }

  set value(val) {
    this.view.dispatch({
      changes: { from: 0, to: this.view.state.doc.length, insert: val },
    });
  }

  set error(error) {
    for (const widget of this.widgets) {
      widget.remove();
    }
    this.widgets.length = 0;

    if (!error) return;

    if (typeof error === "string" || error instanceof String) {
      const msg = ErrorMessage.create(error);
      this.view.dom.before(msg);
      this.widgets.push(msg);
    } else {
      for (const e of error) {
        const msg = ErrorMessage.create(e.message);
        this.view.dom.before(msg);
        this.widgets.push(msg);
      }
    }
  }

  init(container) {
    this.view = Editor.create(
      container,
      {
        lineNumbers: true,
        lineWrapping: false,
        matchBrackets: true,
        mode: "swift",
        readOnly: true,
        screenReaderLabel: "Build DSL View",
      },
      "100%",
      "100%",
    );
    this.widgets = [];
  }
}
