"use strict";

import { EventDispatcher } from "@createjs/easeljs";

export class MatchOptions extends EventDispatcher {
  constructor() {
    super();
    this.init();
  }

  init() {
    document.querySelectorAll(".match-options-item").forEach((listItem) => {
      listItem.addEventListener("click", (event) => {
        listItem.classList.toggle("active-tick");
        this.dispatchEvent("change");
      });
    });
  }

  get value() {
    const options = [];
    document.querySelectorAll(".match-options-item").forEach((listItem) => {
      if (listItem.classList.contains("active-tick")) {
        options.push(listItem.dataset.value);
      }
    });
    return options;
  }

  set value(options) {
    document.querySelectorAll(".match-options-item").forEach((listItem) => {
      if (options.includes(listItem.dataset.value)) {
        listItem.classList.add("active-tick");
      }
    });
  }

  setDefaultValue() {
    this.value = ["g", "m"];
  }
}
