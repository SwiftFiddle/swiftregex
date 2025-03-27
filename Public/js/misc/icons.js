"use strict";

import { config, library, dom } from "@fortawesome/fontawesome-svg-core";
import {
  faFlag,
  faOctagonXmark,
  faHeart,
  faBackwardStep,
  faForwardStep,
  faCaretLeft,
  faCaretRight,
} from "@fortawesome/pro-solid-svg-icons";
import {
  faAt,
  faCheck,
  faCommentAltSmile,
} from "@fortawesome/pro-regular-svg-icons";
import { faMonitorHeartRate } from "@fortawesome/pro-light-svg-icons";
import { faSwift, faGithub } from "@fortawesome/free-brands-svg-icons";

config.searchPseudoElements = true;
library.add(
  faFlag,
  faOctagonXmark,
  faHeart,

  faBackwardStep,
  faForwardStep,
  faCaretLeft,
  faCaretRight,

  faAt,
  faCheck,
  faCommentAltSmile,

  faMonitorHeartRate,

  faSwift,
  faGithub
);
dom.watch();
