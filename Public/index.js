"use strict";

import "./scss/default.scss";
import "codemirror/lib/codemirror.css";
import "tippy.js/dist/tippy.css";
import "./css/common.css";
import "./css/highlight.css";

import "./js/misc/icons";

import Plausible from "plausible-tracker";

const { enableAutoPageviews } = Plausible({
  domain: "swiftregex.com",
});
enableAutoPageviews();

import { Tab } from "bootstrap";
import { App } from "./js/app";

const app = new App();
