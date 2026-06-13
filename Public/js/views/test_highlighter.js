"use strict";

import { StateField, StateEffect } from "@codemirror/state";
import { Decoration, EditorView, WidgetType } from "@codemirror/view";
import { EventDispatcher } from "@createjs/easeljs";
import Utils from "../misc/utils";

class MatchedNewlineWidget extends WidgetType {
  constructor(attrs) {
    super();
    this.attrs = attrs;
  }
  toDOM() {
    const span = document.createElement("span");
    span.className = "match-newline";
    span.textContent = "¬";
    for (const [key, value] of Object.entries(this.attrs)) {
      span.setAttribute(key, value);
    }
    return span;
  }
  eq(other) {
    return JSON.stringify(this.attrs) === JSON.stringify(other.attrs);
  }
}

class AnchorWidget extends WidgetType {
  constructor(className, attrs) {
    super();
    this.className = className;
    this.attrs = attrs;
  }
  toDOM(view) {
    const span = document.createElement("span");
    span.className = this.className;
    span.style.display = "inline-block";
    span.style.height = `${view.defaultLineHeight * 1.5}px`;
    span.style.width = "1px";
    span.style.verticalAlign = "text-top";
    for (const [key, value] of Object.entries(this.attrs)) {
      span.setAttribute(key, value);
    }
    return span;
  }
  eq(other) {
    return (
      this.className === other.className &&
      JSON.stringify(this.attrs) === JSON.stringify(other.attrs)
    );
  }
}

export default class TestHighlighter extends EventDispatcher {
  constructor() {
    super();
    this.view = null;

    this.setMatches = StateEffect.define();

    this.matchesField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setMatches)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });
  }

  get extensions() {
    return [this.matchesField];
  }

  attach(view) {
    this.view = view;
  }

  draw(tokens) {
    const doc = this.view.state.doc;
    const docLen = doc.length;
    const decos = [];

    for (const token of tokens) {
      const match = Utils.htmlSafe(token.value);
      let tooltip = `<div class="text-start font-monospace">
        <div><span class="fw-bolder">match:</span> ${match}</div>
        <div class="fw-bolder">range: ${token.location.start}-${token.location.end}</div>
        </div>`;

      if (token.captures.length) {
        tooltip += "<hr>";
        for (const [i, capture] of token.captures.entries()) {
          const value = Utils.htmlSafe(capture.value || "");
          const name = Utils.htmlSafe(capture.name || "");
          tooltip += `<div class="text-start font-monospace">
            <div><span class="fw-bolder">group #${i + 1}${
              name ? ` ${name}` : ""
            }:</span> ${value === "" ? "empty string" : value}</div>
            </div>`;
        }
      }

      const attrs = { "data-tippy-content": tooltip };

      if (token.location.start < token.location.end) {
        const from = token.location.start;
        const to = Math.min(token.location.end, docLen);
        if (from < docLen) {
          decos.push(
            Decoration.mark({
              class: "match-char",
              attributes: attrs,
            }).range(from, to),
          );

          for (let ln = doc.lineAt(from).number; ln < doc.lines; ln++) {
            const line = doc.line(ln);
            if (line.to >= to) break;
            decos.push(
              Decoration.widget({
                widget: new MatchedNewlineWidget(attrs),
                side: 1,
              }).range(line.to),
            );
          }
        }
      } else {
        const pos = Math.min(token.location.start, docLen);

        if (pos >= docLen) {
          decos.push(
            Decoration.widget({
              widget: new AnchorWidget("match-left", attrs),
              side: -1,
            }).range(pos),
          );
        } else {
          const line = doc.lineAt(pos);
          if (pos < line.to) {
            decos.push(
              Decoration.mark({
                class: "match-left",
                attributes: attrs,
              }).range(pos, pos + 1),
            );
          } else {
            if (pos === line.from) {
              decos.push(
                Decoration.widget({
                  widget: new AnchorWidget("match-left", attrs),
                  side: -1,
                }).range(pos),
              );
            } else {
              decos.push(
                Decoration.widget({
                  widget: new AnchorWidget("match-right", attrs),
                  side: 1,
                }).range(pos),
              );
            }
          }
        }
      }
    }

    this.view.dispatch({
      effects: this.setMatches.of(Decoration.set(decos, true)),
    });
  }

  clear() {
    if (!this.view) {
      return;
    }
    this.view.dispatch({
      effects: this.setMatches.of(Decoration.none),
    });
  }

}
