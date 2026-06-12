"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import tippy from "tippy.js";
import { EditorView } from "@codemirror/view";

import Editor from "./editor";
import ExpressionHighlighter from "./expression_highlighter";
import Utils from "../misc/utils";

export class ExpressionField extends EventDispatcher {
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

  set tokens(tokens) {
    this.expressionTokens = tokens;
    this.highlighter.draw(tokens);
    this.resetTooltips();
  }

  set error(error) {
    if (error && error.length) {
      let message = "";
      if (typeof error === "string" || error instanceof String) {
        const errorMessage = Utils.htmlSafe(error);
        message = `<span class="fw-bolder text-danger">Parse Error:</span> ${errorMessage}`;
      } else {
        message = error
          .map((e) => {
            const errorMessage = Utils.htmlSafe(e.message);
            return `<span class="fw-bolder text-danger">${e.behavior}:</span> ${errorMessage}`;
          })
          .join("<br>");
        this.highlighter.drawError(error);
      }
      this.errorMessageTooltip.setContent(message);
      document
        .getElementById("expression-field-error")
        .classList.remove("d-none");
    } else {
      this.errorMessageTooltip.setContent("");
      document.getElementById("expression-field-error").classList.add("d-none");
      this.highlighter.clearError();
    }

    tippy(".exp-syntax-error", {
      allowHTML: true,
      animation: false,
      placement: "bottom",
    });
  }

  init(container) {
    this.highlighter = new ExpressionHighlighter();

    this.view = Editor.create(
      container,
      {
        autofocus: true,
        maxLength: 2500,
        singleLine: true,
        screenReaderLabel: "Regular Expression Field",
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
    this.expressionTokens = [];
    this.activeTooltips = [];

    this.errorMessageTooltip = tippy(
      document.getElementById("expression-field-error"),
      {
        ...tooltipProps,
      },
    );
  }

  setDefaultValue() {
    this.view.dispatch({
      changes: {
        from: 0,
        to: this.view.state.doc.length,
        insert: defaultValue,
      },
    });
    this.view.dispatch({
      selection: { anchor: this.view.state.doc.length },
    });
  }

  resetTooltips() {
    for (const tooltip of this.activeTooltips) {
      tooltip.destroy();
    }
    this.activeTooltips = tippy(tooltipSelector, {
      ...tooltipProps,
      onShow: (instance) => {
        const index = instance.reference.dataset.tokenIndex;
        if (index === undefined) {
          return false;
        }
        const token = this.expressionTokens[index];
        this.onHover(token, index);
        return false;
      },
    });
  }

  deferUpdate() {
    Utils.defer(() => this.update(), "ExpressionField.update");
  }

  update() {
    this.dispatchEvent("change");
  }

  highlightPattern(range) {
    this.highlighter.clearHover();
    this._hoverTokenIndex = null;
    this.highlighter.highlightRange(range);
    this.resetTooltips();
  }

  clearPatternHighlight() {
    this.highlighter.clearReverseHover();
    this.resetTooltips();
  }

  onHover(token, tokenIndex) {
    this.hoverToken = token;
    this._hoverTokenIndex = tokenIndex;

    this.highlighter.drawHover(token);
    this.dispatchEvent("hover");

    for (const tooltip of this.activeTooltips) {
      tooltip.destroy();
    }

    this.activeTooltips = tippy(tooltipSelector, {
      ...tooltipProps,
      onUntrigger: (instance, event) => {
        if (event) {
          const related = event.relatedTarget?.closest?.(
            "[data-token-index]",
          );
          if (
            related &&
            related.dataset.tokenIndex === this._hoverTokenIndex
          ) {
            return;
          }
        }
        this.highlighter.clearHover();
        this._hoverTokenIndex = null;
        this.resetTooltips();
        this.dispatchEvent("unhover");
      },
    });

    for (const t of this.activeTooltips) {
      if (t.reference.dataset.tokenIndex === tokenIndex) {
        t.show();
        break;
      }
    }
  }
}

const defaultValue = `(CREDIT|DEBIT)\\s+(\\d{1,2}/\\d{1,2}/\\d{4})`;

const tooltipSelector = "#expression-field-container span[data-tippy-content]";
const tooltipProps = {
  allowHTML: true,
  animation: false,
  placement: "bottom",
};
