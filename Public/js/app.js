"use strict";

import { Tooltip } from "bootstrap";
import tippy from "tippy.js";
import { ExpressionField } from "./views/expression_field";
import { MatchOptions } from "./views/match_options";
import { TestEditor } from "./views/test_editor";
import { DSLView } from "./views/dsl_view";
import { DSLEditor } from "./views/dsl_editor";
import { DebuggerText } from "./views/debugger_text";
import { Runner } from "./runner";
import Utils from "./misc/utils";

export class App {
  constructor() {
    this.init();
  }

  init() {
    [].slice
      .call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
      .map((trigger) => {
        return new Tooltip(trigger);
      });

    this.expressionField = new ExpressionField(
      document.getElementById("expression-field-container"),
    );
    this.expressionField.addEventListener("change", () =>
      this.onExpressionFieldChange(),
    );
    this.expressionField.addEventListener("hover", () => {
      const token = this.expressionField.hoverToken;
      if (token) {
        this.dslView.highlight(token);
      }
    });
    this.expressionField.addEventListener("unhover", () => {
      this.dslView.clearHighlight();
    });

    this.matchOptions = new MatchOptions();
    this.matchOptions.addEventListener("change", () =>
      this.onExpressionFieldChange(),
    );

    this.patternTestEditor = new TestEditor(
      document.querySelector(".test-editor-container"),
    );
    this.patternTestEditor.addEventListener("change", () =>
      this.onPatternTestEditorChange(),
    );

    this.debuggerText = new DebuggerText(
      document.getElementById("debugger-text-container"),
    );

    this.debuggerGoStartButton = document.getElementById("debugger-go-start");
    this.debuggerGoStartButton.addEventListener("click", () => {
      const matchStepRange = document.getElementById("debugger-step-range");
      matchStepRange.value = 1;
      this.onDebuggerStepChange();
    });

    this.debuggerStepBackwardButton = document.getElementById(
      "debugger-step-backward",
    );
    this.debuggerStepBackwardButton.addEventListener("click", () => {
      const matchStepRange = document.getElementById("debugger-step-range");
      matchStepRange.value = Math.max(1, parseInt(matchStepRange.value) - 1);
      this.onDebuggerStepChange();
    });

    this.debuggerStepForwardButton = document.getElementById(
      "debugger-step-forward",
    );
    this.debuggerStepForwardButton.addEventListener("click", () => {
      const matchStepRange = document.getElementById("debugger-step-range");
      matchStepRange.value = Math.min(
        parseInt(matchStepRange.value) + 1,
        parseInt(matchStepRange.max),
      );
      this.onDebuggerStepChange();
    });

    this.debuggerGoEndButton = document.getElementById("debugger-go-end");
    this.debuggerGoEndButton.addEventListener("click", () => {
      const matchStepRange = document.getElementById("debugger-step-range");
      matchStepRange.value = matchStepRange.max;
      this.onDebuggerStepChange();
    });

    const matchStepRange = document.getElementById("debugger-step-range");
    matchStepRange.addEventListener("input", () => {
      this.onDebuggerStepChange();
    });

    this.debuggerModal = document.getElementById("debugger-modal");
    this.debuggerModal.addEventListener("shown.bs.modal", () =>
      this.launchDebugger(),
    );

    this.dslView = new DSLView(document.getElementById("dsl-view-container"));
    this.dslView.addEventListener("dslhover", () => {
      const range = this.dslView.hoverPatternRange;
      if (range) {
        this.expressionField.highlightPattern(range);
      }
    });
    this.dslView.addEventListener("dslunhover", () => {
      this.expressionField.clearPatternHighlight();
    });

    this.matchCountTooltip = tippy(
      document.getElementById("match-count"),
      {
        allowHTML: true,
        animation: false,
        placement: "bottom-end",
        interactive: true,
        appendTo: () => document.body,
        content: "",
        onShow: (instance) => {
          if (!instance.props.content) return false;
        },
      },
    );

    this._reqSeq = 0;
    this._latestId = {};

    this.runner = new Runner();
    this.runner.onready = this.onRunnerReady.bind(this);
    this.runner.onresponse = (response) => {
      if (response.id != null && response.id !== this._latestId[response.method]) {
        return;
      }
      this.onRunnerResponse(response);
    };

    this.stateProxy = {
      builder: "",
      text2: "",
    };

    if (window.Worker) {
      this.stateRestorationWorker = new Worker(
        new URL("./state/worker.js", import.meta.url),
      );

      if (window.location.search) {
        this.decodeState();
      } else {
        this.expressionField.setDefaultValue();
        this.patternTestEditor.setDefaultValue();

        this.stateProxy.builder = DSLEditor.defaultValue;
        this.stateProxy.text2 = TestEditor.defaultValue;
      }
      this.startStateRestoration();
    }
  }

  startStateRestoration() {
    if (!this.stateRestorationWorker) {
      return;
    }

    const debounce = (() => {
      const timers = {};
      return function (callback, delay, id) {
        delay = delay || 400;
        id = id || "duplicated event";
        if (timers[id]) {
          clearTimeout(timers[id]);
        }
        timers[id] = setTimeout(callback, delay);
      };
    })();

    this.stateRestorationWorker.onmessage = (e) => {
      if (e.data && e.data.type === "encode") {
        debounce(
          () => {
            history.replaceState(null, "", e.data.value);
          },
          400,
          "update_location",
        );
      }
      if (e.data && e.data.type === "decode") {
        const expressionField = this.expressionField;
        const matchOptions = this.matchOptions;
        const patternTestEditor = this.patternTestEditor;

        if (expressionField) {
          expressionField.value = e.data.value.pattern;
        }
        if (matchOptions) {
          matchOptions.value = e.data.value.options;
        }
        if (patternTestEditor) {
          patternTestEditor.value = e.data.value.text1;
        }
      }
    };
  }

  encodeState() {
    if (!this.stateRestorationWorker) {
      return;
    }

    const expressionField = this.expressionField;
    const matchOptions = this.matchOptions;
    const patternTestEditor = this.patternTestEditor;

    this.stateRestorationWorker.postMessage({
      type: "encode",
      value: {
        pattern: expressionField ? expressionField.value : "",
        options: matchOptions ? matchOptions.value : [],
        text1: patternTestEditor ? patternTestEditor.value : "",
      },
    });
  }

  decodeState() {
    if (!this.stateRestorationWorker) {
      return;
    }

    this.stateRestorationWorker.postMessage({
      type: "decode",
      value: window.location.search,
    });
  }

  showMatchLoading() {
    const matchCount = document.getElementById("match-count");
    matchCount.textContent = "Matching...";
  }

  updateMatchCount(count, id) {
    const matchCount = document.getElementById(id);
    if (count > 1) {
      matchCount.textContent = `${count} matches`;
    } else if (count > 0) {
      matchCount.textContent = "1 match";
    } else {
      matchCount.textContent = "no match";
    }
  }

  launchDebugger() {
    const expressionField = this.expressionField;
    const patternTestEditor = this.patternTestEditor;

    const expression = expressionField.value;
    const text = patternTestEditor.value;

    const matchStepRange = document.getElementById("debugger-step-range");
    matchStepRange.value = 1;
    matchStepRange.min = 1;

    const matchStep = document.getElementById("debugger-match-step");
    matchStep.textContent = "1";

    const debuggerPattern = document.getElementById("debugger-regex");
    debuggerPattern.value = expression;

    this.debuggerText.value = text;

    this.onDebuggerStepChange();
  }

  onExpressionFieldChange() {
    if (!this.expressionField.value) {
      const id = String(++this._reqSeq);
      for (const method of ["parseExpression", "convertToDSL", "match"]) {
        this._latestId[method] = id;
      }
      this.expressionField.tokens = [];
      this.expressionField.error = null;
      this.dslView.value = "";
      this.dslView.error = null;
      this.dslView.sourceMap = [];
      this.updateMatchCount(0, "match-count");
      this.patternTestEditor.matches = [];
      this.patternTestEditor.error = null;
      document.getElementById("debugger-button").disabled = true;
      return;
    }

    this.run();

    this.encodeState();
  }

  run() {
    this.showMatchLoading();
    const id = String(++this._reqSeq);
    const methods = ["parseExpression", "convertToDSL", "match"];
    for (const method of methods) {
      this._latestId[method] = id;
    }
    const params = {
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    };

    if (this.runner.isReady) {
      for (const method of methods) {
        this.runner.run({
          method: method,
          id,
          ...params,
        });
      }
    } else {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      for (const method of methods) {
        const body = JSON.stringify({
          method: method,
          id,
          ...params,
        });
        fetch(`/api/rest/${method}`, { method: "POST", headers, body })
          .then((response) => response.json())
          .then((response) => {
            if (response.id === this._latestId[response.method]) {
              this.onRunnerResponse(response);
            }
          });
      }
    }
  }

  onMatchOptionsChange() {
    this.onPatternTestEditorChange();
  }

  onPatternTestEditorChange() {
    this.showMatchLoading();
    const method = "match";
    const id = String(++this._reqSeq);
    this._latestId[method] = id;
    const params = {
      method,
      id,
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    };

    if (this.runner.isReady) {
      this.runner.run(params);
    } else {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const body = JSON.stringify(params);
      fetch(`/api/rest/${method}`, { method: "POST", headers, body })
        .then((response) => response.json())
        .then((response) => {
          if (response.id === this._latestId[response.method]) {
            this.onRunnerResponse(response);
          }
        });
    }

    this.encodeState();
  }

  onDebuggerStepChange() {
    const method = "debug";
    const id = String(++this._reqSeq);
    this._latestId[method] = id;
    const params = {
      method,
      id,
      pattern: document.getElementById("debugger-regex").value,
      text: this.debuggerText.value,
      matchOptions: this.matchOptions.value,
      step: document.getElementById("debugger-step-range").value,
    };

    if (this.runner.isReady) {
      this.runner.run(params);
    } else {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const body = JSON.stringify(params);
      fetch(`/api/rest/${method}`, { method: "POST", headers, body })
        .then((response) => response.json())
        .then((response) => {
          if (response.id === this._latestId[response.method]) {
            this.onRunnerResponse(response);
          }
        });
    }
  }

  onRunnerReady() {
    const value = this.expressionField.value;
    if (value) {
      this.onExpressionFieldChange();
    }
  }

  onRunnerResponse(response) {
    switch (response.method) {
      case "parseExpression":
        if (response.result) {
          const tokens = JSON.parse(response.result);
          this.expressionField.tokens = tokens;
        } else {
          this.expressionField.tokens = [];
        }
        const debuggerButton = document.getElementById("debugger-button");
        let hasError = false;
        if (response.error) {
          try {
            const error = JSON.parse(response.error);
            if (error && (!Array.isArray(error) || error.length > 0)) {
              this.expressionField.error = error;
              hasError = true;
            }
          } catch (e) {
            this.expressionField.error = response.error;
            hasError = true;
          }
        }
        if (!hasError) {
          this.expressionField.error = null;
        }
        debuggerButton.disabled = hasError || !response.result;
        break;
      case "convertToDSL":
        if (response.result) {
          const dslResult = JSON.parse(response.result);
          if (typeof dslResult === "string") {
            this.dslView.value = dslResult;
            this.dslView.sourceMap = [];
          } else {
            this.dslView.value = dslResult.dsl;
            this.dslView.sourceMap = dslResult.sourceMap;
          }
        }
        if (response.error) {
          try {
            const error = JSON.parse(response.error);
            if (error) {
              this.dslView.error = error;
            }
          } catch (e) {
            this.dslView.error = response.error;
          }
        } else {
          this.dslView.error = null;
        }
        break;
      case "match":
        if (response.result) {
          const matches = JSON.parse(response.result);
          this.patternTestEditor.matches = matches;
          this.updateMatchCount(matches.length, "match-count");
          this.matchCountTooltip.setContent(
            matches.length ? App.buildMatchListTooltip(matches) : "",
          );

          debuggerButton.disabled = matches.length === 0;
        } else {
          this.patternTestEditor.matches = [];
          this.matchCountTooltip.setContent("");
          if (response.error === "Timed out") {
            document.getElementById("match-count").textContent = "Timed out";
          } else {
            this.updateMatchCount(0, "match-count");
          }
          if (response.error && response.error !== "Timed out") {
            document.getElementById("debugger-button").disabled = true;
          }
        }

        this.patternTestEditor.error =
          response.error === "Timed out" ? "" : response.error;

        break;
      case "debug":
        if (response.result) {
          const metrics = JSON.parse(response.result);

          const matchStep = document.getElementById("debugger-match-step");
          matchStep.textContent = metrics.step;

          const matchStepRange = document.getElementById("debugger-step-range");
          matchStepRange.max = metrics.stepCount;

          const matchStepRangeMax = document.getElementById(
            "debugger-step-range-max",
          );
          matchStepRangeMax.textContent = metrics.stepCount;

          const instructions = document.getElementById("debugger-instructions");
          instructions.innerHTML = "";

          metrics.instructions.forEach((instruction, i) => {
            const tr = document.createElement("tr");

            if (i === metrics.programCounter) {
              tr.classList.add("table-primary");
            }

            const programCounter = document.createElement("td");
            programCounter.style =
              "width: 1%; text-align: right; white-space: nowrap; padding-left: 1em; padding-right: 1em;";
            programCounter.textContent = i + 1;
            tr.appendChild(programCounter);

            const inst = document.createElement("td");
            inst.style = "white-space: nowrap;";
            inst.textContent = instruction;
            tr.appendChild(inst);
            instructions.appendChild(tr);
          });

          const totalCycleCount = document.getElementById(
            "debugger-total-cycle-count",
          );
          totalCycleCount.textContent = metrics.totalCycleCount;

          const resets = document.getElementById("debugger-resets");
          resets.textContent = metrics.resets;

          const backtracks = document.getElementById("debugger-backtracks");

          const previousBacktracks = Number(backtracks.textContent);
          backtracks.textContent = metrics.backtracks;

          this.debuggerText.highlighter.draw(
            metrics.traces,
            previousBacktracks < metrics.backtracks ? metrics.failure : null,
          );
        }
        break;
    }
  }

  static buildMatchListTooltip(matches) {
    let html = `<div class="text-start font-monospace" style="min-width:240px;max-width:520px;min-height:120px;max-height:400px;overflow-y:auto;">`;
    html += `<table style="border-collapse:collapse;">`;

    for (const [i, m] of matches.entries()) {
      if (i > 0) {
        html += `<tr><td colspan="3" style="padding:0;height:6px;"></td></tr>`;
      }
      const captureCount = m.captures.length;
      html += App.matchRow(`#${i + 1}`, ".0", m.value, captureCount > 0 ? captureCount + 1 : 0);

      for (const [j, c] of m.captures.entries()) {
        const label = c.name
          ? `.${Utils.htmlSafe(c.name)}`
          : `.${j + 1}`;
        html += App.matchRow(null, label, c.value, 0);
      }
    }

    html += `</table></div>`;
    return html;
  }

  static invisibleCharLabel(cp) {
    const map = {
      0x200D: "ZWJ", 0x200C: "ZWNJ", 0x200B: "ZWS",
      0xFEFF: "BOM", 0xFE0F: "VS16", 0xFE0E: "VS15",
      0x00AD: "SHY", 0x061C: "ALM",
      0x200E: "LRM", 0x200F: "RLM",
      0x2028: "LS", 0x2029: "PS",
      0x202A: "LRE", 0x202B: "RLE", 0x202C: "PDF",
      0x202D: "LRO", 0x202E: "RLO",
      0x2066: "LRI", 0x2067: "RLI", 0x2068: "FSI", 0x2069: "PDI",
    };
    return map[cp] || null;
  }

  static formatDisplayValue(value) {
    const ws = "color:rgba(127,127,127,0.5)";
    const tag = "font-size:0.7em;background:rgba(127,127,127,0.25);border-radius:2px;padding:0 3px;vertical-align:middle;color:rgba(200,200,200,0.8)";
    const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
    let s = "";
    for (const { segment } of segmenter.segment(value)) {
      if (segment === " ") {
        s += `<span style="${ws}">&#x2423;</span>`;
      } else if (segment === "\n") {
        s += `<span style="${ws}">&#xAC;</span>`;
      } else if (segment === "\t") {
        s += `<span style="${ws}">&#x21E5;</span>`;
      } else if (segment === "\r") {
        s += `<span style="${ws}">&#x21B5;</span>`;
      } else if ([...segment].length === 1) {
        const cp = segment.codePointAt(0);
        const label = App.invisibleCharLabel(cp);
        if (label) {
          s += `<span style="${tag}">${label}</span>`;
        } else if (cp < 0x20 || (cp >= 0x7F && cp <= 0x9F)) {
          const hex = cp.toString(16).toUpperCase().padStart(2, "0");
          s += `<span style="${tag}">0x${hex}</span>`;
        } else {
          s += Utils.htmlSafe(segment);
        }
      } else {
        s += Utils.htmlSafe(segment);
      }
    }
    return s;
  }

  static matchRow(num, label, value, rowspan) {
    let display;
    if (value == null) {
      display = `<span style="color:#6c757d;">nil</span>`;
    } else {
      display = App.formatDisplayValue(value);
    }
    let numCell = "";
    if (num) {
      const rs = rowspan > 0 ? ` rowspan="${rowspan}"` : "";
      numCell = `<td style="padding:1px 8px 1px 0;color:#6c757d;vertical-align:top;white-space:nowrap;"${rs}>${num}</td>`;
    }
    return `<tr>
      ${numCell}
      <td style="padding:1px 16px 1px 0;color:#6c757d;vertical-align:top;white-space:nowrap;">${label}</td>
      <td style="padding:1px 0;word-break:break-all;">${display}</td>
    </tr>`;
  }
}
