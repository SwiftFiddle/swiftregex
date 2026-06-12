"use strict";

import { StateField, StateEffect } from "@codemirror/state";
import { Decoration, EditorView } from "@codemirror/view";
import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";
import ErrorMessage from "./error_message";

export class DSLView extends EventDispatcher {
  constructor(container) {
    super();
    this.container = container;
    this._sourceMap = [];
    this._dslHoverEntry = null;
    this.hoverPatternRange = null;

    this.setHighlight = StateEffect.define();
    this.highlightField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setHighlight)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });

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

  set sourceMap(map) {
    this._sourceMap = map || [];
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
        extensions: [
          this.highlightField,
          EditorView.domEventHandlers({
            mousemove: (event) => {
              this.onMouseMove(event);
            },
            mouseleave: () => {
              this.onMouseLeave();
            },
          }),
        ],
      },
      "100%",
      "100%",
    );
    this.widgets = [];
  }

  onMouseMove(event) {
    if (!this._sourceMap.length) return;

    const pos = this.view.posAtCoords({ x: event.clientX, y: event.clientY });
    if (pos == null) {
      this.onMouseLeave();
      return;
    }

    const entry = this.findBestDSLEntry(pos);
    if (
      entry &&
      this._dslHoverEntry &&
      entry.dslStart === this._dslHoverEntry.dslStart &&
      entry.dslEnd === this._dslHoverEntry.dslEnd
    ) {
      return;
    }

    this._dslHoverEntry = entry;
    if (entry) {
      const docLen = this.view.state.doc.length;
      const from = Math.min(entry.dslStart, docLen);
      const to = Math.min(entry.dslEnd, docLen);
      if (from < to) {
        this.view.dispatch({
          effects: this.setHighlight.of(
            Decoration.set([
              Decoration.mark({ class: "dsl-highlight-selected" }).range(
                from,
                to,
              ),
            ]),
          ),
        });
      }

      this.hoverPatternRange = {
        start: entry.patternStart,
        end: entry.patternEnd,
      };
      this.dispatchEvent("dslhover");
    } else {
      this.clearHighlight();
      this.hoverPatternRange = null;
      this.dispatchEvent("dslunhover");
    }
  }

  onMouseLeave() {
    if (this._dslHoverEntry) {
      this._dslHoverEntry = null;
      this.clearHighlight();
      this.hoverPatternRange = null;
      this.dispatchEvent("dslunhover");
    }
  }

  highlight(token) {
    if (!this._sourceMap.length) {
      this.clearHighlight();
      return;
    }

    const docLen = this.view.state.doc.length;
    const decos = [];

    const selRange = token.selection || token.location;
    if (selRange) {
      const entry = this.findBestEntry(selRange);
      if (entry) {
        const from = Math.min(entry.dslStart, docLen);
        const to = Math.min(entry.dslEnd, docLen);
        if (from < to) {
          decos.push(
            Decoration.mark({ class: "dsl-highlight-selected" }).range(
              from,
              to,
            ),
          );
        }
      }
    }

    const relRange = token.related ? token.related.location : null;
    if (relRange) {
      const entry = this.findBestEntry(relRange);
      if (entry) {
        const from = Math.min(entry.dslStart, docLen);
        const to = Math.min(entry.dslEnd, docLen);
        if (from < to) {
          const alreadyCovered = decos.some(
            (d) => d.from === from && d.to === to,
          );
          if (!alreadyCovered) {
            decos.push(
              Decoration.mark({ class: "dsl-highlight-related" }).range(
                from,
                to,
              ),
            );
          }
        }
      }
    }

    this.view.dispatch({
      effects: this.setHighlight.of(
        decos.length ? Decoration.set(decos) : Decoration.none,
      ),
    });

    if (decos.length) {
      this.view.dispatch({
        effects: EditorView.scrollIntoView(decos[0].from, { y: "nearest" }),
      });
    }
  }

  clearHighlight() {
    this.view.dispatch({
      effects: this.setHighlight.of(Decoration.none),
    });
  }

  findBestEntry(patternRange) {
    let best = null;
    for (const entry of this._sourceMap) {
      if (
        entry.patternStart <= patternRange.start &&
        entry.patternEnd >= patternRange.end
      ) {
        if (
          !best ||
          entry.patternEnd - entry.patternStart <
            best.patternEnd - best.patternStart
        ) {
          best = entry;
        }
      }
    }
    return best;
  }

  findBestDSLEntry(dslPos) {
    let best = null;
    for (const entry of this._sourceMap) {
      if (entry.dslStart <= dslPos && entry.dslEnd > dslPos) {
        if (
          !best ||
          entry.dslEnd - entry.dslStart < best.dslEnd - best.dslStart
        ) {
          best = entry;
        }
      }
    }
    return best;
  }
}
