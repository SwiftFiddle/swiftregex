"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";
import Utils from "../misc/utils";

export default class TestHighlighter extends EventDispatcher {
  constructor(editor) {
    super();
    this.editor = editor;
    this.activeMarks = [];
  }

  draw(tokens) {
    this.clear();

    const editor = this.editor;
    editor.operation(() => {
      const doc = editor.getDoc();
      const marks = this.activeMarks;

      for (const token of tokens) {
        const className = "match";
        const location = Editor.calcRangePos(
          this.editor,
          token.location.start,
          token.location.end - token.location.start
        );

        const match = Utils.htmlSafe(token.value);
        let tooltip = `<div class="text-start font-monospace">
        <div><span class="fw-bolder">match:</span> ${match}</div>
        <div class="fw-bolder">range: ${token.location.start}-${token.location.end}</div>
        </div>`;

        if (token.captures.length) {
          tooltip += "<hr>";
          for (const [i, capture] of token.captures.entries()) {
            const value = Utils.htmlSafe(capture.value || "");
            tooltip += `<div class="text-start font-monospace">
            <div><span class="fw-bolder">group #${i + 1}:</span> ${value}</div>
            </div>`;
          }
        }
        marks.push(
          doc.markText(location.startPos, location.endPos, {
            className: className,
            attributes: {
              "data-tippy-content": tooltip,
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
}
