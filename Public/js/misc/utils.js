"use strict";

const Utils = {};
export default Utils;

Utils.copy = function (target, source) {
  for (let n in source) {
    target[n] = source[n];
  }
  return target;
};

Utils.clone = function (o) {
  // this seems hacky, but it's the fastest, easiest approach for now:
  return JSON.parse(JSON.stringify(o));
};

Utils.htmlSafe = function (str) {
  return str == null
    ? ""
    : ("" + str).replace(/&/g, "&amp;").replace(/</g, "&lt;");
};

Utils.shorten = function (str, length, htmlSafe, tag = "") {
  if (!str) {
    return str;
  }
  let b = length > 0 && str.length > length;
  if (b) {
    str = str.substr(0, length - 1);
  }
  if (htmlSafe) {
    str = Utils.htmlSafe(str);
  }
  return !b
    ? str
    : str + (tag && "<" + tag + ">") + "\u2026" + (tag && "</" + tag + ">");
};

Utils.unescSubstStr = function (str) {
  if (!str) {
    return "";
  }
  return str.replace(
    Utils.SUBST_ESC_RE,
    (a, b, c) =>
      Utils.SUBST_ESC_CHARS[b] || String.fromCharCode(parseInt(c, 16))
  );
};

Utils.getRegExp = function (str) {
  // returns a JS RegExp object.
  let match = str.match(/^\/(.+)\/([a-z]+)?$/),
    regex = null;
  try {
    regex = match ? new RegExp(match[1], match[2] || "") : new RegExp(str, "g");
  } catch (e) {}
  return regex;
};

Utils.decomposeRegEx = function (str, delim = "/") {
  let re = new RegExp("^" + delim + "(.*)" + delim + "([igmsuUxy]*)$");
  let match = re.exec(str);
  if (match) {
    return { source: match[1], flags: match[2] };
  } else {
    return { source: str, flags: "g" };
  }
};

Utils.isMac = function () {
  return !!navigator.userAgent.match(/Mac\sOS/i);
};

Utils.getCtrlKey = function () {
  return Utils.isMac() ? "cmd" : "ctrl";
};

Utils.now = function () {
  return window.performance ? performance.now() : Date.now();
};

Utils.getUrlParams = function () {
  let match,
    re = /([^&=]+)=?([^&]*)/g,
    params = {};
  let url = window.location.search.substr(1).replace(/\+/g, " ");
  while ((match = re.exec(url))) {
    params[decodeURIComponent(match[1])] = decodeURIComponent(match[2]);
  }
  return params;
};

let deferIds = {};
Utils.defer = function (f, id, t = 1) {
  clearTimeout(deferIds[id]);
  if (f === null) {
    delete deferIds[id];
    return;
  }
  deferIds[id] = setTimeout(() => {
    delete deferIds[id];
    f();
  }, t);
};

Utils.getHashCode = function (s) {
  let hash = 0,
    l = s.length,
    i;
  for (i = 0; i < l; i++) {
    hash = ((hash << 5) - hash + s.charCodeAt(i)) | 0;
  }
  return hash;
};

Utils.getPatternURL = function (pattern) {
  let a = Utils.isLocal ? "?id=" : "/";
  let url = window.location.origin,
    id = (pattern && pattern.id) || "";
  return url + a + id;
};

Utils.isLocal = window.location.hostname === "localhost";

Utils.getPatternURLStr = function (pattern) {
  if (!pattern || !pattern.id) {
    return null;
  }
  let a = Utils.isLocal ? "?id=" : "/";
  let url = window.location.host,
    id = pattern.id;
  return url + a + id;
};

Utils.SUBST_ESC_CHARS = {
  // this is just the list supported in Replace. Others: b, f, ", etc.
  n: "\n",
  r: "\r",
  t: "\t",
  "\\": "\\",
};

Utils.SUBST_ESC_RE = /\\([nrt\\]|u([A-Z0-9]{4}))/gi;
