"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";
import Utils from "../misc/utils";

export default class TestHighlighter extends EventDispatcher {
  constructor(editor) {
    super();

    this.editor = editor;
    this.activeMarks = [];
    this.widgets = [];

    this.textHeight = editor.defaultTextHeight();
  }

  draw(tokens) {
    this.clear();

    const editor = this.editor;
    editor.operation(() => {
      const doc = editor.getDoc();
      const marks = this.activeMarks;

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
            tooltip += `<div class="text-start font-monospace">
            <div><span class="fw-bolder">group #${i + 1}:</span> ${
              value === "" ? "empty string" : value
            }</div>
            </div>`;
          }
        }

        if (token.location.start < token.location.end) {
          const location = Editor.calcRangePos(
            editor,
            token.location.start,
            token.location.end - token.location.start
          );
          marks.push(
            doc.markText(location.startPos, location.endPos, {
              className: "match-char",
              attributes: {
                "data-tippy-content": tooltip,
              },
            })
          );
        } else {
          const location = Editor.calcRangePos(editor, token.location.start, 1);

          if (
            location.startPos.line === location.endPos.line &&
            location.startPos.ch === location.endPos.ch
          ) {
            this.addLeftAnchor(location, { "data-tippy-content": tooltip });
          }
          if (location.startPos.line === location.endPos.line) {
            if (location.startPos.ch < location.endPos.ch) {
              marks.push(
                doc.markText(location.startPos, location.endPos, {
                  className: "match-left",
                  attributes: {
                    "data-tippy-content": tooltip,
                  },
                })
              );
            } else {
              // this.addRightAnchor(location, { "data-tippy-content": tooltip });
            }
          } else {
            if (location.startPos.ch === 0 && location.endPos.ch === 0) {
              this.addLeftAnchor(location, { "data-tippy-content": tooltip });
            } else {
              this.addRightAnchor(location, { "data-tippy-content": tooltip });
            }
          }
        }
      }
    });
  }

  addLeftAnchor(location, attributes = {}) {
    const widget = document.createElement("span");
    widget.className = "match-left";

    widget.style.height = `${this.textHeight * 1.5}px`;
    widget.style.width = "1px";
    widget.style.zIndex = "10";

    for (const [key, value] of Object.entries(attributes)) {
      widget.setAttribute(key, value);
    }

    this.editor.addWidget(location.startPos, widget);

    const coords = this.editor.charCoords(location.startPos, "local");
    widget.style.left = `${coords.left}px`;
    widget.style.top = `${coords.top + 2}px`;

    this.widgets.push(widget);
  }

  addRightAnchor(location, attributes = {}) {
    const widget = document.createElement("span");
    widget.className = "match-right";

    widget.style.height = `${this.textHeight * 1.5}px`;
    widget.style.width = "1px";
    widget.style.zIndex = "10";

    for (const [key, value] of Object.entries(attributes)) {
      widget.setAttribute(key, value);
    }

    this.editor.addWidget(location.endPos, widget);

    const coords = this.editor.charCoords(location.startPos, "local");
    widget.style.left = `${coords.left}px`;
    widget.style.top = `${coords.top + 2}px`;

    this.widgets.push(widget);
  }

  clear() {
    this.editor.operation(() => {
      let marks = this.activeMarks;
      for (var i = 0, l = marks.length; i < l; i++) {
        marks[i].clear();
      }
      marks.length = 0;

      for (const widget of this.widgets) {
        widget.parentNode.removeChild(widget);
      }
      this.widgets.length = 0;
    });
  }
}
