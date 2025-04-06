"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import { Reference } from "../docs/reference";
import Editor from "./editor";

export default class ExpressionHighlighter extends EventDispatcher {
  constructor(editor) {
    super();
    this.editor = editor;
    this.activeMarks = [];
    this.hoverMarks = [];
    this.widgets = [];
  }

  draw(tokens) {
    this.clear();

    const pre = ExpressionHighlighter.CSS_PREFIX;
    const editor = this.editor;
    editor.operation(() => {
      const doc = editor.getDoc();
      const marks = this.activeMarks;

      for (const [i, token] of Object.entries(tokens)) {
        const location = Editor.calcRangePos(
          this.editor,
          token.location.start,
          token.location.end - token.location.start
        );

        const tooltipAttr = (() => {
          if (token.tooltip) {
            const reference = Reference.get(
              token.tooltip.category,
              token.tooltip.key
            );
            let title = reference ? reference.title : token.tooltip.category;
            let detail = reference ? reference.detail : token.tooltip.key;
            for (const [k, v] of Object.entries(token.tooltip.substitution)) {
              title = title.replaceAll(k, v);
              detail = detail.replaceAll(k, v);
            }
            return {
              "data-tippy-content": makeTooltip(title, detail),
            };
          } else {
            return {};
          }
        })();
        marks.push(
          doc.markText(location.startPos, location.endPos, {
            className: `${token.classes.map((c) => `${pre}-${c}`).join(" ")}`,
            attributes: {
              ...tooltipAttr,
              "data-token-index": i,
            },
          })
        );
      }
    });
  }

  drawError(errors) {
    this.clearError();

    const pre = ExpressionHighlighter.CSS_PREFIX;
    const editor = this.editor;
    editor.operation(() => {
      for (const error of errors) {
        const location = Editor.calcRangePos(
          this.editor,
          error.location.start,
          error.location.end - error.location.start
        );
        const widget = document.createElement("span");
        widget.className = `${pre}-syntax-error`;

        widget.style.height = `5px`;
        widget.style.zIndex = "10";
        widget.setAttribute(
          "data-tippy-content",
          `<span class="fw-bolder text-danger">${error.behavior}:</span> ${error.message}`
        );

        editor.addWidget(location.startPos, widget);
        const startCoords = editor.charCoords(location.startPos, "local");
        const endCoords = editor.charCoords(location.endPos, "local");
        widget.style.left = `${startCoords.left + 1}px`;
        widget.style.top = `${startCoords.bottom - 1}px`;
        widget.style.width = `${endCoords.left - startCoords.left - 2}px`;

        this.widgets.push(widget);
      }
    });
  }

  clear() {
    this.editor.operation(() => {
      for (const mark of this.activeMarks) {
        mark.clear();
      }
      this.activeMarks.length = 0;
    });
  }

  clearError() {
    this.editor.operation(() => {
      for (const widget of this.widgets) {
        widget.parentNode.removeChild(widget);
      }
      this.widgets.length = 0;
    });
  }

  drawHover(token) {
    const selection = token.selection;
    const related = token.related;
    if ((!selection && !related) || this.hoverMarks.length) {
      return;
    }

    this.clearHover();

    if (selection) {
      this.drawBorder(selection, "selected");
    }
    if (related) {
      this.drawBorder(related.location, "related");
    }
  }

  drawBorder(range, className) {
    const editor = this.editor;
    const doc = editor.getDoc();

    const pre = ExpressionHighlighter.CSS_PREFIX;
    const left = Editor.calcRangePos(this.editor, range.start, 1);
    const location = Editor.calcRangePos(
      this.editor,
      range.start,
      range.end - range.start
    );
    const right = Editor.calcRangePos(this.editor, range.end - 1, 1);
    this.hoverMarks.push(
      doc.markText(left.startPos, left.endPos, {
        className: `${pre}-${className}-left`,
      })
    );
    this.hoverMarks.push(
      doc.markText(location.startPos, location.endPos, {
        className: `${pre}-${className}`,
      })
    );
    this.hoverMarks.push(
      doc.markText(right.startPos, right.endPos, {
        className: `${pre}-${className}-right`,
      })
    );
  }

  clearHover() {
    this.editor.operation(() => {
      for (const mark of this.hoverMarks) {
        mark.clear();
      }
      this.hoverMarks.length = 0;
    });
  }
}

function makeTooltip(label, desc) {
  return `<div class="text-start"><span class="fw-bolder">${label}.</span><span> ${desc}</span></div>`;
}

ExpressionHighlighter.CSS_PREFIX = "exp";
