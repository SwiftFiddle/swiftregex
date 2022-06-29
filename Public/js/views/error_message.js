"use strict";

const ErrorMessage = {};
export default ErrorMessage;

ErrorMessage.create = (message) => {
  const container = document.createElement("div");
  container.classList.add("error-message", "d-flex", "flex-row");
  const wrapper = document.createElement("div");
  wrapper.classList.add("d-flex", "flex-row", "overflow-hidden", "w-100");
  container.appendChild(wrapper);
  const iconWrapper = document.createElement("div");
  wrapper.appendChild(iconWrapper);
  const icon = document.createElement("span");
  icon.classList.add(
    "fa-solid",
    "fa-octagon-xmark",
    "fa-xs",
    "text-danger",
    "px-2"
  );
  iconWrapper.appendChild(icon);
  const messageWrapper = document.createElement("div");
  messageWrapper.classList.add("text-nowrap");
  messageWrapper.textContent = message;
  wrapper.appendChild(messageWrapper);

  return container;
};
