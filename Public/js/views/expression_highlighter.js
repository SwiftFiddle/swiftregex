"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";
import { Reference } from "../docs/Reference";

export default class ExpressionHighlighter extends EventDispatcher {
  constructor(editor) {
    super();
    this.editor = editor;
    this.activeMarks = [];
    this.hoverMarks = [];
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

  clear() {
    this.editor.operation(() => {
      let marks = this.activeMarks;
      for (var i = 0, l = marks.length; i < l; i++) {
        marks[i].clear();
      }
      marks.length = 0;
    });
  }

  drawHover(token) {
    const selection = token.selection;
    const related = token.related;
    if ((!selection && !related) || this.hoverMarks.length) {
      return;
    }

    while (this.hoverMarks.length) {
      this.hoverMarks.pop().clear();
    }

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
    while (this.hoverMarks.length) {
      this.hoverMarks.pop().clear();
    }
  }
}

function makeTooltip(label, desc) {
  return `<div class="text-start"><span class="fw-bolder">${label}.</span><span> ${desc}</span></div>`;
}

ExpressionHighlighter.CSS_PREFIX = "exp";
