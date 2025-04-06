"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import tippy from "tippy.js";

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
    return this.editor.getValue();
  }

  set value(val) {
    this.editor.setValue(val);
  }

  set tokens(tokens) {
    this.expressionTokens = tokens;
    this.highlighter.draw(tokens);
    this.resetTooltips();
  }

  set error(error) {
    if (error) {
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

    tippy(".exp-error", {
      allowHTML: true,
      animation: false,
      placement: "bottom",
    });
  }

  init(container) {
    this.editor = Editor.create(
      container,
      {
        autofocus: true,
        maxLength: 2500,
        singleLine: true,
        screenReaderLabel: "Regular Expression Field",
      },
      "100%",
      "100%"
    );

    this.editor.on("change", (editor, event) =>
      this.onEditorChange(editor, event)
    );

    this.highlighter = new ExpressionHighlighter(this.editor);
    this.expressionTokens = [];
    this.activeTooltips = [];

    this.errorMessageTooltip = tippy(
      document.getElementById("expression-field-error"),
      {
        ...tooltipProps,
      }
    );
  }

  setDefaultValue() {
    this.editor.setValue(defaultValue);
    this.editor.setCursor(this.editor.lineCount(), 0);
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
        this.onHover(token, instance);
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

  onEditorChange(editor, event) {
    this.deferUpdate();
  }

  onHover(token, tippyInstance) {
    this.hoverToken = token;

    this.highlighter.drawHover(token);
    this.dispatchEvent("hover");

    for (const tooltip of this.activeTooltips) {
      if (tooltip !== tippyInstance) {
        tooltip.destroy();
      }
    }
    this.activeTooltips = tippy(tooltipSelector, {
      ...tooltipProps,
      onUntrigger: (instance) => {
        this.highlighter.clearHover();
        this.resetTooltips();
        this.dispatchEvent("unhover");
      },
    });
  }
}

const defaultValue = `(CREDIT|DEBIT)\\s+(\\d{1,2}/\\d{1,2}/\\d{4})`;

const tooltipSelector = "#expression-field-container span[data-tippy-content]";
const tooltipProps = {
  allowHTML: true,
  animation: false,
  placement: "bottom",
};
