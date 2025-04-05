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
    return this.editor.getValue();
  }

  set value(val) {
    this.editor.setValue(val);
  }

  set error(error) {
    const editor = this.editor;
    const widgets = this.widgets;

    editor.operation(function () {
      for (const widget of widgets) {
        editor.removeLineWidget(widget);
      }
      widgets.length = 0;

      if (!error) {
        return;
      }
      if (typeof error === "string" && error instanceof String) {
        widgets.push(
          editor.addLineWidget(0, ErrorMessage.create(error), {
            coverGutter: false,
            noHScroll: true,
            above: true,
          })
        );
      } else {
        for (const e of error) {
          const message = ErrorMessage.create(e.message);
          widgets.push(
            editor.addLineWidget(0, message, {
              coverGutter: false,
              noHScroll: true,
              above: true,
            })
          );
        }
      }
    });
  }

  init(container) {
    this.editor = Editor.create(
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
      "100%"
    );
    this.widgets = [];
  }
}
