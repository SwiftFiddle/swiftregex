"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import tippy from "tippy.js";

import Editor from "./editor";
import TestHighlighter from "./test_highlighter";
import ErrorMessage from "./error_message";
import Utils from "../misc/utils";

const defaultValue = `KIND      DATE          INSTITUTION                AMOUNT
----------------------------------------------------------------
CREDIT    03/01/2022    Payroll from employer      $200.23
CREDIT    03/03/2022    Suspect A                  $2,000,000.00
DEBIT     03/03/2022    Ted's Pet Rock Sanctuary   $2,000,000.00
DEBIT     03/05/2022    Doug's Dugout Dogs         $33.27
DEBIT     06/03/2022    Oxford Comma Supply Ltd.   £57.33
`;

export class TestEditor extends EventDispatcher {
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

  set matches(matches) {
    this.highlighter.draw(matches);
    tippy(".test-editor-container span[data-tippy-content]", {
      allowHTML: true,
      animation: false,
      placement: "bottom",
    });
  }

  init(container) {
    const editor = Editor.create(
      container,
      { lineWrapping: true, screenReaderLabel: "Pattern Test View" },
      "100%",
      "100%"
    );
    this.editor = editor;

    this.highlighter = new TestHighlighter(editor);
    this.widgets = [];

    editor.on("change", (editor, event) => this.onEditorChange(editor, event));
  }

  setDefaultValue() {
    this.editor.setValue(defaultValue);
  }

  deferUpdate() {
    Utils.defer(() => this.update(), "TestEditor.update");
  }

  update() {
    this.dispatchEvent("change");
  }

  onEditorChange(editor, event) {
    this.deferUpdate();
  }
}
