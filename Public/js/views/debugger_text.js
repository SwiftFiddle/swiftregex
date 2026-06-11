"use strict";

import Editor from "./editor";
import DebuggerHighlighter from "./debugger_highlighter";

export class DebuggerText {
  constructor(container) {
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

  init(container) {
    this.highlighter = new DebuggerHighlighter();

    this.view = Editor.create(
      container,
      {
        lineWrapping: true,
        showNewlines: true,
        screenReaderLabel: "Debugger Test View",
        readOnly: true,
        extensions: [...this.highlighter.extensions],
      },
      "100%",
      "100%",
    );

    this.highlighter.attach(this.view);
  }
}
