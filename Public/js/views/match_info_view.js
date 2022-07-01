"use strict";

import { EventDispatcher } from "@createjs/easeljs";

export class MatchInfoView extends EventDispatcher {
  constructor(container) {
    super();
    this.container = container;
    this.init(container);
  }

  set matches(matches) {
    this.container.innerHTML = "";

    for (const match of matches) {
      const table = document.createElement("table");
      this.container.appendChild(table);
      table.classList.add(
        "table",
        "table-sm",
        "table-borderless",
        "table-striped",
        "my-1"
      );
      const tbody = document.createElement("tbody");
      table.appendChild(tbody);
      const tr = document.createElement("tr");
      tbody.appendChild(tr);
      const td1 = document.createElement("td");
      tr.appendChild(td1);
      td1.textContent = "Match";
      const td2 = document.createElement("td");
      tr.appendChild(td2);
      td2.textContent = match.value;
      const td3 = document.createElement("td");
      tr.appendChild(td3);
      td3.textContent = `${match.location.start}-${match.location.end}`;
      const td4 = document.createElement("td");
      tr.appendChild(td4);
      td4.textContent = "";

      for (const [i, capture] of match.captures.entries()) {
        const table = document.createElement("table");
        table.classList.add(
          "table",
          "table-sm",
          "table-borderless",
          "table-striped",
          "my-1"
        );
        const tr = document.createElement("tr");
        tbody.appendChild(tr);
        const td1 = document.createElement("td");
        tr.appendChild(td1);
        td1.textContent = `Group #${i + 1}`;
        const td2 = document.createElement("td");
        tr.appendChild(td2);
        td2.textContent = capture.value;
        const td3 = document.createElement("td");
        tr.appendChild(td3);
        td3.textContent = `${capture.location.start}-${capture.location.end}`;
        const td4 = document.createElement("td");
        tr.appendChild(td4);
        td4.innerHTML = `<code>${capture.type}</code>`;
      }
    }
  }

  init(container) {}
}
