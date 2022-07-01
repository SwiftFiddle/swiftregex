"use strict";

import { ExpressionField } from "./views/expression_field";
import { MatchOptions } from "./views/match_options";
import { TestEditor } from "./views/test_editor";
import { DSLView } from "./views/dsl_view";

import { DSLEditor } from "./views/dsl_editor";
import { MatchInfoView } from "./views/match_info_view";

import { DSLHighlighter } from "./views/dsl_highlighter";

import { WasmRunner } from "./wasm_runner";

export class App {
  constructor() {
    this.init();
  }

  init() {
    this.expressionField = new ExpressionField(
      document.getElementById("expression-field-container")
    );
    this.expressionField.addEventListener("change", () =>
      this.onExpressionFieldChange()
    );
    this.expressionField.addEventListener("hover", () => {
      this.onExpressionFieldHover();
    });
    this.expressionField.addEventListener("unhover", () => {
      this.onExpressionFieldUnhover();
    });

    this.matchOptions = new MatchOptions();
    this.matchOptions.addEventListener("change", () =>
      this.onExpressionFieldChange()
    );

    this.patternTestEditor = new TestEditor(
      document.querySelector(".pattern-tab-pane.test-editor-container")
    );
    this.patternTestEditor.addEventListener("change", () =>
      this.onPatternTestEditorChange()
    );

    this.dslView = new DSLView(document.getElementById("dsl-view-container"));

    const tabEl = document.getElementById("builder-tab");
    tabEl.addEventListener("shown.bs.tab", (event) => {
      if (!this.dslEditor) {
        this.dslEditor = new DSLEditor(
          document.getElementById("dsl-editor-container")
        );
        this.dslEditor.addEventListener("change", () =>
          this.onDSLEditorChange()
        );
        this.dslEditor.value = this.stateProxy.builder;

        this.runButton = document.getElementById("run-button");
        this.runButton.addEventListener("click", () => {
          this.onDSLEditorRunClick();
        });
      }

      if (!this.builderTestEditor) {
        this.builderTestEditor = new TestEditor(
          document.querySelector(".builder-tab-pane.test-editor-container")
        );
        this.builderTestEditor.addEventListener("change", () =>
          this.onBuilderTestEditorChange()
        );
        this.builderTestEditor.value = this.stateProxy.text2;
      }

      if (!this.matchInfoView) {
        this.matchInfoView = new MatchInfoView(
          document.getElementById("match-info-container")
        );
      }

      this.onDSLEditorChange();
    });

    this.runner = new WasmRunner();
    this.runner.onready = this.onRunnerReady.bind(this);
    this.runner.onresponse = this.onRunnerResponse.bind(this);

    this.dslHighlighter = new DSLHighlighter(this.dslView.editor);
    this.dslTokens = [];

    this.stateProxy = {
      builder: "",
      text2: "",
    };

    if (window.Worker) {
      this.stateRestorationWorker = new Worker(
        new URL("./state/worker.js", import.meta.url)
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
          "update_location"
        );
      }
      if (e.data && e.data.type === "decode") {
        const expressionField = this.expressionField;
        const matchOptions = this.matchOptions;
        const patternTestEditor = this.patternTestEditor;
        const dslEditor = this.dslEditor;
        const builderTestEditor = this.builderTestEditor;

        if (expressionField) {
          expressionField.value = e.data.value.pattern;
        }
        if (matchOptions) {
          matchOptions.value = e.data.value.options;
        }
        if (patternTestEditor) {
          patternTestEditor.value = e.data.value.text1;
        }
        if (dslEditor) {
          dslEditor.value = e.data.value.builder;
        } else {
          this.stateProxy.builder = DSLEditor.defaultValue;
        }
        if (builderTestEditor) {
          builderTestEditor.value = e.data.value.text2;
        } else {
          this.stateProxy.text2 = TestEditor.defaultValue;
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
    const dslEditor = this.dslEditor;
    const builderTestEditor = this.builderTestEditor;

    this.stateRestorationWorker.postMessage({
      type: "encode",
      value: {
        pattern: expressionField ? expressionField.value : "",
        options: matchOptions ? matchOptions.value : [],
        text1: patternTestEditor ? patternTestEditor.value : "",
        builder: dslEditor ? dslEditor.value : "",
        text2: builderTestEditor ? builderTestEditor.value : "",
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

  onExpressionFieldChange() {
    if (!this.expressionField.value) {
      this.updateMatchCount(0, "match-count");
      return;
    }

    this.run();

    this.encodeState();
  }

  run() {
    const methods = ["parseExpression", "convertToDSL", "match", "parseDSL"];
    const params = {
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    };

    if (this.runner.isReady) {
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
        const body = JSON.stringify({
          method: method,
          ...params,
        });
        fetch(`/api/rest/${method}`, { method: "POST", headers, body })
          .then((response) => {
            return response.json();
          })
          .then((response) => {
            this.onRunnerResponse(response);
          });
      }
    }
  }

  onExpressionFieldHover() {
    const related = this.expressionField.hoverToken.related;
    const location =
      (related && related.location) || this.expressionField.hoverToken.location;
    const tokens = this.dslTokens
      .filter(
        (token) =>
          token.patternLocation.start <= location.start &&
          token.patternLocation.end >= location.end
      )
      .map((token) => {
        return {
          ...token,
          sourceLength: token.sourceLocation.end - token.sourceLocation.start,
          patternLength:
            token.patternLocation.end - token.patternLocation.start,
        };
      });
    tokens.sort(
      (a, b) =>
        a.patternLength - b.patternLength || a.sourceLength - b.sourceLength
    );
    this.dslHighlighter.draw(tokens.slice(0, 1));
  }

  onExpressionFieldUnhover() {
    this.dslHighlighter.clear();
  }

  onMatchOptionsChange() {
    this.onPatternTestEditorChange();
  }

  onPatternTestEditorChange() {
    this.runner.run({
      method: "match",
      pattern: this.expressionField.value,
      text: this.patternTestEditor.value,
      matchOptions: this.matchOptions.value,
    });

    this.encodeState();
  }

  onDSLEditorChange() {
    this.encodeState();
  }

  onDSLEditorRunClick() {
    document.getElementById("run-button-icon").classList.add("d-none");
    document.getElementById("run-button-spinner").classList.remove("d-none");

    const method = "POST";
    const params = {
      method: "testBuilder",
      pattern: this.dslEditor.value,
      text: this.builderTestEditor.value,
      matchOptions: this.matchOptions.value,
    };
    const body = JSON.stringify(params);
    const headers = {
      Accept: "application/json",
      "Content-Type": "application/json",
    };
    fetch("/api/rest/testBuilder", { method, headers, body })
      .then((response) => {
        return response.json();
      })
      .then((response) => {
        const result = response.result;
        if (result && result.trim()) {
          const matches = JSON.parse(response.result);
          this.builderTestEditor.matches = matches;
          this.matchInfoView.matches = matches;
          this.updateMatchCount(matches.length, "dsl-match-count");
        } else {
          this.builderTestEditor.matches = [];
          this.matchInfoView.matches = [];
          this.updateMatchCount(0, "dsl-match-count");
        }
        const error = response.error;
        if (error && error.trim()) {
          this.dslEditor.error = error;
        } else {
          this.dslEditor.error = "";
        }
      })
      .catch((error) => {})
      .finally(() => {
        document.getElementById("run-button-icon").classList.remove("d-none");
        document.getElementById("run-button-spinner").classList.add("d-none");
      });
  }

  onBuilderTestEditorChange() {
    this.runner.run({
      method: "testBuilder",
      pattern: this.dslEditor.value,
      text: this.builderTestEditor.value,
      matchOptions: this.matchOptions.value,
    });

    this.encodeState();
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
        this.expressionField.error = response.error;
        break;
      case "convertToDSL":
        if (response.result) {
          this.dslView.value = JSON.parse(response.result);
        }
        this.dslView.error = response.error;
        break;
      case "match":
        if (response.result) {
          const matches = JSON.parse(response.result);
          this.patternTestEditor.matches = matches;
          this.updateMatchCount(matches.length, "match-count");
        } else {
          this.patternTestEditor.matches = [];
          this.updateMatchCount(0, "match-count");
        }
        this.patternTestEditor.error = response.error;
        break;
      case "parseDSL":
        if (response.result) {
          const tokens = JSON.parse(response.result);
          this.dslTokens = tokens;
        } else {
          this.dslTokens = [];
        }
        this.dslView.error = response.error;
        break;
      case "testBuilder":
        break;
    }
  }
}
