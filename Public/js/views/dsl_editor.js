"use strict";

import { EventDispatcher } from "@createjs/easeljs";

import Editor from "./editor";
import ErrorMessage from "./error_message";
import Utils from "../misc/utils";

const defaultValue = `Regex {
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
  OneOrMore(.whitespace)
  Capture {
    Regex {
      Repeat(1...2) {
        One(.digit)
      }
      "/"
      Repeat(1...2) {
        One(.digit)
      }
      "/"
      Repeat(count: 4) {
        One(.digit)
      }
    }
  }
}
`;

export class DSLEditor extends EventDispatcher {
  static defaultValue = defaultValue;

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

      widgets.push(
        editor.addLineWidget(0, ErrorMessage.create(error), {
          coverGutter: false,
          noHScroll: true,
          above: true,
        })
      );
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
        screenReaderLabel: "Build DSL Editor",
      },
      "100%",
      "100%"
    );
    this.editor.setValue(defaultValue);
    this.editor.setCursor(this.editor.lineCount(), 0);
    this.editor.on("change", (editor, event) =>
      this.onEditorChange(editor, event)
    );

    this.widgets = [];
  }

  setDefaultValue() {
    this.editor.setValue(defaultValue);
  }

  deferUpdate() {
    Utils.defer(() => this.update(), "DSLEditor.update");
  }

  update() {
    this.dispatchEvent("change");
  }

  onEditorChange(editor, event) {
    this.deferUpdate();
  }
}
