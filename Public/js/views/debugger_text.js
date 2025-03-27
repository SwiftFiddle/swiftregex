"use strict";

import Editor from "./editor";
import DebuggerHighlighter from "./debugger_highlighter";

export class DebuggerText {
  constructor(container) {
    this.container = container;
    this.init(container);
  }

  get value() {
    return this.editor.getValue();
  }

  set value(val) {
    this.editor.setValue(val);
  }

  init(container) {
    const editor = Editor.create(
      container,
      {
        lineWrapping: true,
        screenReaderLabel: "Debugger Test View",
        readOnly: true,
      },
      "100%",
      "100%"
    );
    this.editor = editor;

    this.highlighter = new DebuggerHighlighter(editor);
  }
}
