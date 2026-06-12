"use strict";

import { EventDispatcher } from "@createjs/easeljs";

export class MatchOptions extends EventDispatcher {
  constructor() {
    super();
    this.init();
  }

  init() {
    document.querySelectorAll(".match-options-item").forEach((listItem) => {
      listItem.addEventListener("click", () => {
        listItem.classList.toggle("active-tick");
        this.dispatchEvent("change");
      });
    });

    document.querySelectorAll(".match-options-radio").forEach((listItem) => {
      listItem.addEventListener("click", () => {
        const group = listItem.dataset.group;
        document
          .querySelectorAll(`.match-options-radio[data-group="${group}"]`)
          .forEach((item) => item.classList.remove("active-tick"));
        listItem.classList.add("active-tick");
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
    document
      .querySelectorAll(".match-options-radio.active-tick")
      .forEach((listItem) => {
        if (!listItem.dataset.default) {
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

    const groups = new Set();
    document.querySelectorAll(".match-options-radio").forEach((listItem) => {
      groups.add(listItem.dataset.group);
    });
    for (const group of groups) {
      const items = document.querySelectorAll(
        `.match-options-radio[data-group="${group}"]`,
      );
      const activeItem = [...items].find((item) =>
        options.includes(item.dataset.value),
      );
      if (activeItem) {
        items.forEach((item) => item.classList.remove("active-tick"));
        activeItem.classList.add("active-tick");
      }
    }
  }

  setDefaultValue() {
    this.value = ["g", "m"];
    document.querySelectorAll(".match-options-radio").forEach((listItem) => {
      if (listItem.dataset.default) {
        listItem.classList.add("active-tick");
      } else {
        listItem.classList.remove("active-tick");
      }
    });
  }
}
