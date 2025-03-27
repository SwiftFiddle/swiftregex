"use strict";

import Editor from "./editor";

export default class DebuggerHighlighter {
  constructor(editor) {
    this.editor = editor;
    this.activeMarks = [];
    this.widgets = [];
  }

  draw(traces, backtrack) {
    this.clear();

    const editor = this.editor;
    editor.operation(() => {
      const doc = editor.getDoc();
      const marks = this.activeMarks;

      const defaultTextHeight = editor.defaultTextHeight();

      for (const trace of traces) {
        const className = "debuggermatch";
        const location = Editor.calcRangePos(
          this.editor,
          trace.location.start,
          trace.location.end - trace.location.start
        );
        marks.push(
          doc.markText(location.startPos, location.endPos, {
            className: className,
          })
        );

        if (trace.location.start === trace.location.end) {
          const pos = doc.posFromIndex(trace.location.start);

          const widget = document.createElement("span");
          widget.className = className;

          widget.style.position = "absolute";
          widget.style.zIndex = "10";

          widget.style.height = `${defaultTextHeight * 1.5}px`;
          widget.style.width = "1px";

          const coords = editor.charCoords(pos, "local");
          widget.style.left = `${coords.left}px`;
          widget.style.top = `${coords.top + 2}px`;

          editor.getWrapperElement().appendChild(widget);

          this.widgets.push(widget);
        }
      }

      if (backtrack) {
        const pos = doc.posFromIndex(backtrack.start);

        const widget = document.createElement("span");
        widget.className = "debuggerbacktrack";

        widget.style.position = "absolute";
        widget.style.zIndex = "10";
        widget.style.height = `${defaultTextHeight * 1.5}px`;
        widget.style.width = `${editor.defaultCharWidth()}px`;

        const coords = editor.charCoords(pos, "local");
        widget.style.left = `${coords.left}px`;
        widget.style.top = `${coords.top + 2}px`;

        editor.getWrapperElement().appendChild(widget);

        this.widgets.push(widget);
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

      for (const widget of this.widgets) {
        widget.remove();
      }
      this.widgets.length = 0;
    });
  }
}
