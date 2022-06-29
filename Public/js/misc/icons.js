"use strict";

import { config, library, dom } from "@fortawesome/fontawesome-svg-core";
import {
  faBracketsCurly,
  faFlag,
  faOctagonXmark,
  faPlay,
} from "@fortawesome/pro-solid-svg-icons";
import {
  faAt,
  faCheck,
  faCommentAltSmile,
} from "@fortawesome/pro-regular-svg-icons";
import { faMonitorHeartRate } from "@fortawesome/pro-light-svg-icons";
import { faSpinnerThird } from "@fortawesome/pro-duotone-svg-icons";
import { faSwift, faGithub } from "@fortawesome/free-brands-svg-icons";

config.searchPseudoElements = true;
library.add(
  faBracketsCurly,
  faFlag,
  faOctagonXmark,
  faPlay,

  faAt,
  faCheck,
  faCommentAltSmile,

  faMonitorHeartRate,

  faSpinnerThird,

  faSwift,
  faGithub
);
dom.watch();
