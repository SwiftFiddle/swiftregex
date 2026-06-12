"use strict";

import { Tooltip } from "bootstrap";
import { ExpressionField } from "./views/expression_field";
import { MatchOptions } from "./views/match_options";
import { TestEditor } from "./views/test_editor";
import { DSLView } from "./views/dsl_view";
import { DSLEditor } from "./views/dsl_editor";
import { DebuggerText } from "./views/debugger_text";
import { Runner } from "./runner";

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

    this._pendingCounts = {};
    this._reqSeq = 0;
    this._httpGens = {};

    this.runner = new Runner();
    this.runner.onready = this.onRunnerReady.bind(this);
    this.runner.onresponse = (response) => {
      const method = response.method;
      if (this._pendingCounts[method] > 0) {
        this._pendingCounts[method]--;
      }
      if (this._pendingCounts[method] > 0) return;
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
      this.expressionField.tokens = [];
      this.expressionField.error = null;
      this.dslView.value = "";
      this.dslView.error = null;
      this.dslView.sourceMap = [];
      this.updateMatchCount(0, "match-count");
      return;
    }

    this.run();

    this.encodeState();
  }

  run() {
    this.showMatchLoading();
    const methods = ["parseExpression", "convertToDSL", "match"];
    const params = {
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    };

    if (this.runner.isReady) {
      for (const method of methods) {
        this._pendingCounts[method] =
          (this._pendingCounts[method] || 0) + 1;
      }
      for (const method of methods) {
        this.runner.run({
          method: method,
          ...params,
        });
      }
    } else {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      for (const method of methods) {
        const seq = (this._httpGens[method] = ++this._reqSeq);
        const body = JSON.stringify({
          method: method,
          ...params,
        });
        fetch(`/api/rest/${method}`, { method: "POST", headers, body })
          .then((response) => response.json())
          .then((response) => {
            if (this._httpGens[response.method] === seq) {
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
    const params = {
      method,
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    };

    if (this.runner.isReady) {
      this._pendingCounts[method] =
        (this._pendingCounts[method] || 0) + 1;
      this.runner.run(params);
    } else {
      const seq = (this._httpGens[method] = ++this._reqSeq);
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const body = JSON.stringify(params);
      fetch(`/api/rest/${method}`, { method: "POST", headers, body })
        .then((response) => response.json())
        .then((response) => {
          if (this._httpGens[response.method] === seq) {
            this.onRunnerResponse(response);
          }
        });
    }

    this.encodeState();
  }

  onDebuggerStepChange() {
    const method = "debug";
    const params = {
      method,
      pattern: document.getElementById("debugger-regex").value,
      text: this.debuggerText.value,
      matchOptions: this.matchOptions.value,
      step: document.getElementById("debugger-step-range").value,
    };

    if (this.runner.isReady) {
      this._pendingCounts[method] =
        (this._pendingCounts[method] || 0) + 1;
      this.runner.run(params);
    } else {
      const seq = (this._httpGens[method] = ++this._reqSeq);
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const body = JSON.stringify(params);
      fetch(`/api/rest/${method}`, { method: "POST", headers, body })
        .then((response) => response.json())
        .then((response) => {
          if (this._httpGens[response.method] === seq) {
            this.onRunnerResponse(response);
          }
        });
    }
  }

  onRunnerReady() {
    this._pendingCounts = {};
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
        if (response.error) {
          try {
            const error = JSON.parse(response.error);
            if (error) {
              this.expressionField.error = error;
            }
          } catch (e) {
            this.expressionField.error = response.error;
          }
        } else {
          this.expressionField.error = null;
        }
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
        const debuggerButton = document.getElementById("debugger-button");

        if (response.result) {
          const matches = JSON.parse(response.result);
          this.patternTestEditor.matches = matches;
          this.updateMatchCount(matches.length, "match-count");

          debuggerButton.disabled = matches.length === 0;
        } else {
          this.patternTestEditor.matches = [];
          if (response.error === "Timed out") {
            document.getElementById("match-count").textContent = "Timed out";
          } else {
            this.updateMatchCount(0, "match-count");
          }

          debuggerButton.disabled = true;
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
}
