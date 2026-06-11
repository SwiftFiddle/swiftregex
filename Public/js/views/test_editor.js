"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import tippy from "tippy.js";
import { EditorView } from "@codemirror/view";

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

    const msg = ErrorMessage.create(error);
    this.view.dom.before(msg);
    this.widgets.push(msg);
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
    this.highlighter = new TestHighlighter();

    this.view = Editor.create(
      container,
      {
        lineWrapping: true,
        showNewlines: true,
        screenReaderLabel: "Pattern Test View",
        extensions: [
          ...this.highlighter.extensions,
          EditorView.updateListener.of((update) => {
            if (update.docChanged) {
              this.deferUpdate();
            }
          }),
        ],
      },
      "100%",
      "100%",
    );

    this.highlighter.attach(this.view);
    this.widgets = [];
  }

  setDefaultValue() {
    this.view.dispatch({
      changes: {
        from: 0,
        to: this.view.state.doc.length,
        insert: defaultValue,
      },
    });
  }

  deferUpdate() {
    Utils.defer(() => this.update(), "TestEditor.update");
  }

  update() {
    this.dispatchEvent("change");
  }
}
