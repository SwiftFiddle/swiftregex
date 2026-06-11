"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import { EditorView } from "@codemirror/view";

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

  init(container) {
    this.view = Editor.create(
      container,
      {
        lineNumbers: true,
        lineWrapping: false,
        matchBrackets: true,
        mode: "swift",
        screenReaderLabel: "Build DSL Editor",
        extensions: [
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

    this.view.dispatch({
      changes: { from: 0, to: 0, insert: defaultValue },
    });
    this.view.dispatch({
      selection: { anchor: this.view.state.doc.length },
    });

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
    Utils.defer(() => this.update(), "DSLEditor.update");
  }

  update() {
    this.dispatchEvent("change");
  }
}
