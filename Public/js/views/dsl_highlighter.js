"use strict";

import { EventDispatcher } from "@createjs/easeljs";
import Editor from "./editor";

export class DSLHighlighter extends EventDispatcher {
  constructor(editor) {
    super();
    this.editor = editor;
    this.activeMarks = [];
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

  draw(tokens) {
    const editor = this.editor;

    this.clear();
    editor.operation(() => {
      const doc = editor.getDoc();
      const marks = this.activeMarks;

      for (const token of tokens) {
        const className = "highlight";
        const location = Editor.calcRangePos(
          this.editor,
          token.sourceLocation.start,
          token.sourceLocation.end - token.sourceLocation.start
        );
        marks.push(
          doc.markText(location.startPos, location.endPos, {
            className: className,
          })
        );
      }
    });
  }
}
