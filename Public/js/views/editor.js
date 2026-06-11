"use strict";

import { EditorState, RangeSetBuilder } from "@codemirror/state";
import {
  EditorView,
  keymap,
  highlightSpecialChars,
  ViewPlugin,
  Decoration,
  WidgetType,
  lineNumbers,
} from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { bracketMatching, StreamLanguage } from "@codemirror/language";
import { swift } from "@codemirror/legacy-modes/mode/swift";

const Editor = {};
export default Editor;

const spaceMark = Decoration.mark({ class: "cm-space" });

function buildSpaceDecorations(view) {
  const builder = new RangeSetBuilder();
  for (const { from, to } of view.visibleRanges) {
    const text = view.state.doc.sliceString(from, to);
    for (let i = 0; i < text.length; i++) {
      if (text[i] === " ") {
        builder.add(from + i, from + i + 1, spaceMark);
      }
    }
  }
  return builder.finish();
}

const spaceHighlighter = ViewPlugin.fromClass(
  class {
    constructor(view) {
      this.decorations = buildSpaceDecorations(view);
    }
    update(update) {
      if (update.docChanged || update.viewportChanged) {
        this.decorations = buildSpaceDecorations(update.view);
      }
    }
  },
  { decorations: (v) => v.decorations },
);

class NewlineWidget extends WidgetType {
  toDOM() {
    const span = document.createElement("span");
    span.className = "cm-newline";
    span.textContent = "¬";
    return span;
  }
}

const newlineWidget = Decoration.widget({
  widget: new NewlineWidget(),
  side: 1,
});

function buildNewlineDecorations(view) {
  const builder = new RangeSetBuilder();
  const doc = view.state.doc;
  for (const { from, to } of view.visibleRanges) {
    let pos = from;
    while (pos <= to) {
      const line = doc.lineAt(pos);
      if (line.number < doc.lines) {
        builder.add(line.to, line.to, newlineWidget);
      }
      pos = line.to + 1;
    }
  }
  return builder.finish();
}

const newlineHighlighter = ViewPlugin.fromClass(
  class {
    constructor(view) {
      this.decorations = buildNewlineDecorations(view);
    }
    update(update) {
      if (update.docChanged || update.viewportChanged) {
        this.decorations = buildNewlineDecorations(update.view);
      }
    }
  },
  { decorations: (v) => v.decorations },
);

Editor.create = (target, opts = {}, width = "100%", height = "100%") => {
  const extensions = [
    keymap.of([...defaultKeymap, ...historyKeymap]),
    history(),
    highlightSpecialChars({
      specialChars: new RegExp("[\u0000-\u0008\u000e-\u001f\u007f-\u009f\u00ad\u061c\u200b\u200c\u200e\u200f\u2028\u2029\ufeff]", "g"),
    }),
    spaceHighlighter,
    EditorView.theme({
      "&": {
        fontFamily:
          'Consolas, Monaco, "Andale Mono", "Ubuntu Mono", monospace',
        maxHeight: "90vh",
        flex: "1",
        minWidth: "0",
        overflow: "hidden",
      },
      ".cm-content": {
        fontFamily:
          'Consolas, Monaco, "Andale Mono", "Ubuntu Mono", monospace',
      },
      ".cm-scroller": {
        overflow: "auto",
      },
    }),
  ];

  if (opts.lineNumbers) {
    extensions.push(lineNumbers());
  }

  if (opts.lineWrapping) {
    extensions.push(EditorView.lineWrapping);
  }

  if (opts.matchBrackets) {
    extensions.push(bracketMatching());
  }

  if (opts.mode === "swift") {
    extensions.push(StreamLanguage.define(swift));
  }

  if (opts.readOnly) {
    extensions.push(EditorState.readOnly.of(true));
    extensions.push(EditorView.editable.of(false));
  }

  if (opts.tabSize) {
    extensions.push(EditorState.tabSize.of(opts.tabSize));
  }

  if (opts.singleLine) {
    extensions.push(
      EditorState.transactionFilter.of((tr) => {
        if (!tr.docChanged) return tr;
        let hasNewline = false;
        tr.changes.iterChanges((fromA, toA, fromB, toB, inserted) => {
          if (inserted.toString().includes("\n")) hasNewline = true;
        });
        if (!hasNewline) return tr;
        const changes = [];
        tr.changes.iterChanges((fromA, toA, fromB, toB, inserted) => {
          changes.push({
            from: fromA,
            to: toA,
            insert: inserted.toString().replace(/[\n\r]/g, ""),
          });
        });
        return [{ changes }];
      }),
    );
  }

  if (opts.maxLength) {
    const maxLength = opts.maxLength;
    extensions.push(
      EditorState.transactionFilter.of((tr) => {
        if (!tr.docChanged || tr.newDoc.length <= maxLength) return tr;
        return [
          {
            changes: {
              from: 0,
              to: tr.state.doc.length,
              insert: tr.newDoc.sliceString(0, maxLength),
            },
          },
        ];
      }),
    );
  }

  if (opts.showNewlines) {
    extensions.push(newlineHighlighter);
  }

  if (opts.screenReaderLabel) {
    extensions.push(
      EditorView.contentAttributes.of({
        "aria-label": opts.screenReaderLabel,
      }),
    );
  }

  if (opts.extensions) {
    extensions.push(...opts.extensions);
  }

  const state = EditorState.create({
    doc: "",
    extensions,
  });

  const view = new EditorView({
    state,
    parent: target,
  });

  if (width) view.dom.style.width = width;
  if (height) view.dom.style.height = height;

  if (opts.autofocus) {
    view.focus();
  }

  return view;
};
