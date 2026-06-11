"use strict";

import { StateField, StateEffect } from "@codemirror/state";
import { Decoration, EditorView, WidgetType } from "@codemirror/view";

class TraceWidget extends WidgetType {
  constructor(className, useCharWidth) {
    super();
    this.className = className;
    this.useCharWidth = useCharWidth;
  }
  toDOM(view) {
    const span = document.createElement("span");
    span.className = this.className;
    span.style.display = "inline-block";
    span.style.height = `${view.defaultLineHeight * 1.5}px`;
    span.style.width = this.useCharWidth
      ? `${view.defaultCharacterWidth}px`
      : "1px";
    span.style.verticalAlign = "text-top";
    return span;
  }
  eq(other) {
    return (
      this.className === other.className &&
      this.useCharWidth === other.useCharWidth
    );
  }
}

export default class DebuggerHighlighter {
  constructor() {
    this.view = null;

    this.setTraces = StateEffect.define();

    this.tracesField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setTraces)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });
  }

  get extensions() {
    return [this.tracesField];
  }

  attach(view) {
    this.view = view;
  }

  draw(traces, backtrack) {
    const docLen = this.view.state.doc.length;
    const decos = [];

    for (const trace of traces) {
      const from = trace.location.start;
      const to = trace.location.end;

      if (from !== to && from < docLen) {
        decos.push(
          Decoration.mark({ class: "debuggermatch" }).range(
            from,
            Math.min(to, docLen),
          ),
        );
      } else if (from <= docLen) {
        decos.push(
          Decoration.widget({
            widget: new TraceWidget("debuggermatch", false),
            side: 1,
          }).range(Math.min(from, docLen)),
        );
      }
    }

    if (backtrack && backtrack.start <= docLen) {
      decos.push(
        Decoration.widget({
          widget: new TraceWidget("debuggerbacktrack", true),
          side: 1,
        }).range(Math.min(backtrack.start, docLen)),
      );
    }

    this.view.dispatch({
      effects: this.setTraces.of(Decoration.set(decos, true)),
    });
  }

  clear() {
    if (!this.view) return;
    this.view.dispatch({
      effects: this.setTraces.of(Decoration.none),
    });
  }
}
