"use strict";

import CodeMirror from "codemirror";
import "codemirror/mode/swift/swift";

import Utils from "../misc/utils";

const Editor = {};
export default Editor;

Editor.create = (target, opts = {}, width = "100%", height = "100%") => {
  const keys = {};

  const o = Utils.copy(
    {
      extraKeys: keys,
      indentWithTabs: false,
      lineNumbers: false,
      mode: "null",
      specialChars:
        /[ \u0000-\u001f\u007f-\u009f\u00ad\u061c\u200b-\u200f\u2028\u2029\ufeff]/,
      specialCharPlaceholder: (ch) =>
        createElement("span", ch === " " ? "cm-space" : "cm-special", " "), // needs to be a space so wrapping works
      tabSize: 2,
    },
    opts
  );

  const cm = CodeMirror(target, o);
  cm.setSize(width, height);

  if (cm.getOption("maxLength")) {
    cm.on("beforeChange", Editor.enforceMaxLength);
  }
  if (cm.getOption("singleLine")) {
    cm.on("beforeChange", Editor.enforceSingleLine);
  }

  return cm;
};

Editor.getCharRect = (cm, index) => {
  if (index == null) {
    return null;
  }
  let pos = cm.posFromIndex(index),
    rect = cm.charCoords(pos);
  rect.x = rect.left;
  rect.y = rect.top;
  rect.width = rect.right - rect.left;
  rect.height = rect.bottom - rect.top;
  return rect;
};

Editor.enforceMaxLength = (cm, change) => {
  let maxLength = cm.getOption("maxLength");
  if (maxLength && change.update) {
    let str = change.text.join("\n");
    let delta =
      str.length - (cm.indexFromPos(change.to) - cm.indexFromPos(change.from));
    if (delta <= 0) {
      return true;
    }
    delta = cm.getValue().length + delta - maxLength;
    if (delta > 0) {
      str = str.substr(0, str.length - delta);
      change.update(change.from, change.to, str.split("\n"));
    }
  }
  return true;
};

Editor.enforceSingleLine = (cm, change) => {
  if (change.update) {
    let str = change.text.join("").replace(/(\n|\r)/g, "");
    change.update(change.from, change.to, [str]);
  }
  return true;
};

Editor.selectAll = (cm) => {
  cm.focus();
  cm.setSelection({ ch: 0, line: 0 }, { ch: 0, line: cm.lineCount() });
};

Editor.calcRangePos = (cm, i, l = 0, o = {}) => {
  let doc = cm.getDoc();
  o.startPos = doc.posFromIndex(i);
  o.endPos = doc.posFromIndex(i + l);
  return o;
};

function createElement(type, className, content, parent) {
  let element = document.createElement(type || "div");
  if (className) {
    element.className = className;
  }
  if (content) {
    if (content instanceof HTMLElement) {
      element.appendChild(content);
    } else {
      element.innerHTML = content;
    }
  }
  if (parent) {
    parent.appendChild(element);
  }
  return element;
}
