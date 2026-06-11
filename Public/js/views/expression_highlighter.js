"use strict";

import { StateField, StateEffect } from "@codemirror/state";
import { Decoration, EditorView, WidgetType } from "@codemirror/view";
import { EventDispatcher } from "@createjs/easeljs";
import { Reference } from "../docs/reference";

class ErrorMarkerWidget extends WidgetType {
  constructor(tooltip) {
    super();
    this.tooltip = tooltip;
  }
  toDOM(view) {
    const span = document.createElement("span");
    span.className = "exp-syntax-error exp-syntax-error-widget";
    span.style.display = "inline-block";
    span.style.width = `${view.defaultCharacterWidth}px`;
    span.setAttribute("data-tippy-content", this.tooltip);
    return span;
  }
  eq(other) {
    return this.tooltip === other.tooltip;
  }
}

export default class ExpressionHighlighter extends EventDispatcher {
  constructor() {
    super();
    this.view = null;
    this._hasHover = false;

    this.setTokens = StateEffect.define();
    this.setErrors = StateEffect.define();
    this.setHover = StateEffect.define();

    this.tokensField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setTokens)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });

    this.errorsField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setErrors)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });

    this.hoverField = StateField.define({
      create: () => Decoration.none,
      update: (value, tr) => {
        for (const e of tr.effects) {
          if (e.is(this.setHover)) return e.value;
        }
        return tr.docChanged ? Decoration.none : value;
      },
      provide: (f) => EditorView.decorations.from(f),
    });
  }

  get extensions() {
    return [this.tokensField, this.errorsField, this.hoverField];
  }

  attach(view) {
    this.view = view;
  }

  draw(tokens) {
    const pre = ExpressionHighlighter.CSS_PREFIX;
    const docLen = this.view.state.doc.length;
    const decos = [];

    for (const [i, token] of Object.entries(tokens)) {
      const from = token.location.start;
      const to = token.location.end;
      if (from >= to || from >= docLen) continue;
      const clampedTo = Math.min(to, docLen);

      const attrs = { "data-token-index": String(i) };
      if (token.tooltip) {
        const reference = Reference.get(
          token.tooltip.category,
          token.tooltip.key,
        );
        let title = reference ? reference.title : token.tooltip.category;
        let detail = reference ? reference.detail : token.tooltip.key;
        for (const [k, v] of Object.entries(token.tooltip.substitution)) {
          title = title.replaceAll(k, v);
          detail = detail.replaceAll(k, v);
        }
        attrs["data-tippy-content"] = makeTooltip(title, detail);
      }

      decos.push(
        Decoration.mark({
          class: token.classes.map((c) => `${pre}-${c}`).join(" "),
          attributes: attrs,
        }).range(from, clampedTo),
      );
    }

    this.view.dispatch({
      effects: this.setTokens.of(Decoration.set(decos, true)),
    });
  }

  drawError(errors) {
    this.clearError();
    const docLen = this.view.state.doc.length;
    const decos = [];

    for (const error of errors) {
      const from = error.location.start;
      const to = error.location.end;
      const tooltip = `<span class="fw-bolder text-danger">${error.behavior}:</span> ${error.message}`;

      if (from < to && from < docLen) {
        decos.push(
          Decoration.mark({
            class: "exp-syntax-error",
            attributes: { "data-tippy-content": tooltip },
          }).range(from, Math.min(to, docLen)),
        );
      } else if (from <= docLen) {
        decos.push(
          Decoration.widget({
            widget: new ErrorMarkerWidget(tooltip),
            side: 1,
          }).range(Math.min(from, docLen)),
        );
      }
    }

    this.view.dispatch({
      effects: this.setErrors.of(Decoration.set(decos, true)),
    });
  }

  clear() {
    if (!this.view) return;
    this.view.dispatch({
      effects: this.setTokens.of(Decoration.none),
    });
  }

  clearError() {
    if (!this.view) return;
    this.view.dispatch({
      effects: this.setErrors.of(Decoration.none),
    });
  }

  drawHover(token) {
    const selection = token.selection;
    const related = token.related;
    if ((!selection && !related) || this._hasHover) {
      return;
    }
    this._hasHover = true;

    const decos = [];
    if (selection) {
      decos.push(...this.makeBorderDecos(selection, "selected"));
    }
    if (related) {
      decos.push(...this.makeBorderDecos(related.location, "related"));
    }

    this.view.dispatch({
      effects: this.setHover.of(Decoration.set(decos, true)),
    });
  }

  makeBorderDecos(range, className) {
    const pre = ExpressionHighlighter.CSS_PREFIX;
    const docLen = this.view.state.doc.length;
    if (range.start >= docLen || range.end > docLen) return [];
    if (range.end - range.start < 1) return [];

    return [
      Decoration.mark({ class: `${pre}-${className}-left` }).range(
        range.start,
        range.start + 1,
      ),
      Decoration.mark({ class: `${pre}-${className}` }).range(
        range.start,
        range.end,
      ),
      Decoration.mark({ class: `${pre}-${className}-right` }).range(
        range.end - 1,
        range.end,
      ),
    ];
  }

  clearHover() {
    this._hasHover = false;
    if (!this.view) return;
    this.view.dispatch({
      effects: this.setHover.of(Decoration.none),
    });
  }
}

function makeTooltip(label, desc) {
  return `<div class="text-start"><span class="fw-bolder">${label}.</span><span> ${desc}</span></div>`;
}

ExpressionHighlighter.CSS_PREFIX = "exp";
