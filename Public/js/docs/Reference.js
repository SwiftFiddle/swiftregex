"use strict";

export class Reference {
  static get(category, key) {
    return references[category][key];
  }
}

const references = {
  charclasses: {
    label: "Character classes",
    desc: "Character classes match a character from a specific set. There are a number of predefined character classes and you can also define your own sets.",

    set: {
      title: "Character set",
      detail: "Match any character in the set.",
    },
    setnot: {
      title: "Negated set",
      detail: "Match any character that is not in the set.",
    },
    range: {
      title: "Range",
      detail:
        "Matches a character in the range {{getChar(prev)}} to {{getChar(next)}} (char code {{prev.code}} to {{next.code}}). {{getInsensitive()}}",
    },
    posixcharclass: {
      title: "POSIX class",
      detail:
        "Matches any character in the specified POSIX class. Must be in a character set. For example, <code>[[:alnum:]$]</code> will match alphanumeric characters and <code>$</code>.",
    },
    dot: {
      title: "Dot",
      detail: "Matches any character {{getDotAll()}}.",
    },
    matchanyset: {
      title: "Match any",
      detail:
        "A character set that can be used to match any character, including line breaks, without the dotall flag (<code>s</code>)." +
        "<p>An alternative is <code>[^]</code>, but it is not supported in all browsers.</p>",
    },
    unicodegrapheme: {
      title: "Unicode grapheme",
      detail: "Matches any single unicode grapheme (ie. character).",
    },
    word: {
      title: "Word",
      detail: "Matches any word character (alphanumeric & underscore).",
    },
    notword: {
      title: "Not word",
      detail:
        "Matches any character that is not a word character (alphanumeric & underscore).",
    },
    digit: {
      title: "Digit",
      detail: "Matches any digit character (0-9).",
    },
    notdigit: {
      title: "Not digit",
      detail: "Matches any character that is not a digit character (0-9).",
    },
    whitespace: {
      title: "Whitespace",
      detail: "Matches any whitespace character (spaces, tabs, line breaks).",
    },
    notwhitespace: {
      title: "Not whitespace",
      detail:
        "Matches any character that is not a whitespace character (spaces, tabs, line breaks).",
    },
    hwhitespace: {
      title: "Horizontal whitespace",
      detail: "Matches any horizontal whitespace character (spaces, tabs).",
    },
    nothwhitespace: {
      title: "Not horizontal whitespace",
      detail:
        "Matches any character that is not a horizontal whitespace character (spaces, tabs).",
    },
    vwhitespace: {
      title: "Vertical whitespace",
      detail: "Matches any vertical whitespace character (line breaks).",
    },
    notvwhitespace: {
      title: "Not vertical whitespace",
      detail:
        "Matches any character that is not a vertical whitespace character (line breaks).",
    },
    linebreak: {
      title: "Line break",
      detail:
        "Matches any line break character, including the CRLF pair, and CR / LF individually.",
    },
    notlinebreak: {
      title: "Not line break",
      detail: "Matches any character that is not a line break.",
    },
    unicodecat: {
      title: "Unicode category",
      detail:
        "Matches any character in the '{{getUniCat()}}' unicode category.",
    },
    notunicodecat: {
      title: "Not unicode category",
      detail:
        "Matches any character that is not in the '{{getUniCat()}}' unicode category.",
    },
    unicodescript: {
      title: "Unicode script",
      detail: "Matches any character in the '{{value}}' unicode script.",
    },
    notunicodescript: {
      title: "Not unicode script",
      detail:
        "Matches any character that is not in the '{{value}}' unicode script.",
    },

    binary: {
      title: "Unicode property escapes",
      detail:
        "Allows for matching characters based on their Unicode properties.",
    },
    script: {
      title: "Script",
      detail: "No overview available.",
    },
    scriptextension: {
      title: "Script extension",
      detail: "No overview available.",
    },
    named: {
      title: "Named",
      detail: "No overview available.",
    },
    numerictype: {
      title: "Numeric type",
      detail: "No overview available.",
    },
    numericvalue: {
      title: "Numeric value",
      detail: "No overview available.",
    },
    mapping: {
      title: "Mapping",
      detail: "No overview available.",
    },
    ccc: {
      title: "Custom character class",
      detail: "No overview available.",
    },
    age: {
      title: "Age",
      detail: "No overview available.",
    },
    block: {
      title: "Block",
      detail: "No overview available.",
    },
    pcrespecial: {
      title: "PCRE special",
      detail: "No overview available.",
    },
    javaspecial: {
      title: "Java special",
      detail: "No overview available.",
    },

    graphemecluster: {
      title: "Grapheme cluster",
      detail: "No overview available.",
    },
    trueanychar: {
      title: "Any character",
      detail: "Equivalent to (?m:.)",
    },
    textsegment: {
      title: "Text segment",
      detail: `Equivalent to (?>\O(?:\Y\O)*)`,
    },
    nottextsegment: {
      title: "Not text segment",
      detail: "Text segment non-boundary",
    },
    keyboardcontrol: {
      title: "Control char",
      detail: "No overview available.",
    },
    keyboardmeta: {
      title: "Meta",
      detail: "No overview available.",
    },
    keyboardmetacontrol: {
      title: "Meta control char",
      detail: "No overview available.",
    },
    namedcharacter: {
      title: "Named character",
      detail: "No overview available.",
    },
    subpattern: {
      title: "Subpattern",
      detail: "No overview available.",
    },
    callout: {
      title: "Callout",
      detail: "No overview available.",
    },

    accept: {
      title: "Backtracking control",
      detail: `This verb causes the match to end successfully, skipping the remainder of the pattern. When inside a recursion, only the innermost pattern is ended immediately.`,
    },
    fail: {
      title: "Backtracking control",
      detail: `This verb causes the match to fail, forcing backtracking to occur. It is equivalent to (?!) but easier to read. The Perl documentation notes that it is probably useful only when combined with (?{}) or (??{}).`,
    },
    mark: {
      title: "Backtracking control",
      detail: "No overview available.",
    },
    commit: {
      title: "Backtracking control",
      detail: `This verb causes the whole match to fail outright if the rest of the pattern does not match. Even if the pattern is unanchored, no further attempts to find a match by advancing the start point take place. Once (*COMMIT) has been passed, re:run/3 is committed to finding a match at the current starting point, or not at all.`,
    },
    prune: {
      title: "Backtracking control",
      detail: `acktracking cannot cross (*PRUNE). In simple cases, the use of (*PRUNE) is just an alternative to an atomic group or possessive quantifier, but there are some uses of (*PRUNE) that cannot be expressed in any other way.`,
    },
    skip: {
      title: "Backtracking control",
      detail: `This verb is like (*PRUNE), except that if the pattern is unanchored, the "bumpalong" advance is not to the next character, but to the position in the subject where (*SKIP) was encountered. (*SKIP) signifies that whatever text was matched leading up to it cannot be part of a successful match.`,
    },
    then: {
      title: "Backtracking control",
      detail: `This verb causes a skip to the next alternation if the rest of the pattern does not match. That is, it cancels pending backtracking, but only within the current alternation.`,
    },
  },

  anchors: {
    label: "Anchors",
    desc: "Anchors are unique in that they match a position within a string, not a character.",

    bos: {
      title: "Beginning of string",
      detail: "Matches the beginning of the string.",
    },
    eos: {
      title: "End of string",
      detail: "Matches the end of the string.",
    },
    abseos: {
      title: "Strict end of string",
      detail:
        "Matches the end of the string. Unlike <code>$</code> or <code>\\Z</code>, it does not allow for a trailing newline.",
    },
    bof: {
      title: "Beginning",
      detail:
        "Matches the beginning of the string, or the beginning of a line if the multiline flag (<code>m</code>) is enabled.",
    },
    eof: {
      title: "End",
      detail:
        "Matches the end of the string, or the end of a line if the multiline flag (<code>m</code>) is enabled.",
    },
    wordboundary: {
      title: "Word boundary",
      detail:
        "Matches a word boundary position between a word character and non-word character or position (start / end of string).",
    },
    notwordboundary: {
      title: "Not word boundary",
      detail: "Matches any position that is not a word boundary.",
    },
    prevmatchend: {
      title: "Previous match end",
      detail: "Matches the end position of the previous match.",
    },
  },

  escchars: {
    label: "Escaped characters",
    desc: "Escape sequences can be used to insert reserved, special, and unicode characters. All escaped characters begin with the <code>\\</code> character.",

    reservedchar: {
      title: "Reserved characters",
      detail:
        "The following character have special meaning, and should be preceded by a <code>\\</code> (backslash) to represent a literal character:" +
        "<p><code>{{getEscChars()}}</code></p>" +
        "<p>Within a character set, only <code>\\</code>, <code>-</code>, and <code>]</code> need to be escaped.</p>",
    },
    escoctal: {
      title: "Octal escape",
      detail: "Octal escaped character in the form <code>\\000</code>.",
    },
    eschexadecimal: {
      title: "Hexadecimal escape",
      detail: "Hexadecimal escaped character in the form <code>\\xFF</code>.",
    },
    escunicodeu: {
      title: "Unicode escape",
      detail: "Unicode escaped character in the form <code>\\uFFFF</code>",
    },
    escunicodeub: {
      title: "Extended unicode escape",
      detail: "Unicode escaped character in the form <code>\\u{FFFF}</code>.",
    },
    escunicodexb: {
      title: "Unicode escape",
      detail: "Unicode escaped character in the form <code>\\x{FF}</code>.",
    },
    esccontrolchar: {
      title: "Control character escape",
      detail: "Escaped control character in the form <code>\\cZ</code>.",
    },
    escsequence: {
      title: "Escape sequence",
      detail: "Matches the literal string '{{value}}'.",
    },
  },

  groups: {
    label: "Groups & References",
    desc: "Groups allow you to combine a sequence of tokens to operate on them together. Capture groups can be referenced by a backreference and accessed separately in the results.",

    group: {
      title: "Capturing group #{{group.num}}",
      detail:
        "Groups multiple tokens together and creates a capture group for extracting a substring or using a backreference.",
    },
    namedgroup: {
      title: "Named capturing group",
      detail: "Creates a capturing group named '{{name}}'.",
    },
    namedref: {
      title: "Named reference",
      detail:
        "Matches the results of the capture group named '{{group.name}}'.",
    },
    numref: {
      title: "Numeric reference",
      detail: "Matches the results of capture group #{{group.num}}.",
    },
    branchreset: {
      title: "Branch reset group",
      detail: "Define alternative groups that share the same group numbers.",
    },
    noncapgroup: {
      title: "Non-capturing group",
      detail:
        "Groups multiple tokens together without creating a capture group.",
    },
    atomic: {
      title: "Atomic group",
      detail:
        "Non-capturing group that discards backtracking positions once matched.",
    },
    define: {
      title: "Define",
      detail:
        "Used to define named groups for use as subroutines without including them in the match.",
    },
    numsubroutine: {
      title: "Numeric subroutine",
      detail: "Matches the expression in capture group #{{group.num}}.",
    },
    namedsubroutine: {
      title: "Named subroutine",
      detail:
        "Matches the expression in the capture group named '{{group.name}}'.",
    },
    balancedcapture: {
      title: "Balancing group",
      detail:
        "This allows nested constructs to be matched, such as parentheses or HTML tags. The previously defined group to balance against is specified by previous. Captures subpattern as a named group specified by name, or name can be omitted to capture as an unnamed group.",
    },

    absentfunction: {
      title: "Absent function",
      detail: "No overview available.",
    },
  },

  lookaround: {
    label: "Lookaround",
    desc:
      "Lookaround lets you match a group before (lookbehind) or after (lookahead) your main pattern without including it in the result." +
      "<p>Negative lookarounds specify a group that can NOT match before or after the pattern.</p>",

    poslookahead: {
      title: "Positive lookahead",
      detail:
        "Matches a group after the main expression without including it in the result.",
    },
    neglookahead: {
      title: "Negative lookahead",
      detail:
        "Specifies a group that can not match after the main expression (if it matches, the result is discarded).",
    },
    poslookbehind: {
      title: "Positive lookbehind",
      detail:
        "Matches a group before the main expression without including it in the result.",
    },
    neglookbehind: {
      title: "Negative lookbehind",
      detail:
        "Specifies a group that can not match before the main expression (if it matches, the result is discarded).",
    },
    keepout: {
      title: "Keep out",
      detail:
        "Keep text matched so far out of the returned match, essentially discarding the match up to this point.",
    },
    nonatomicposlookahead: {
      title: "Non-atomic Positive lookahead",
      detail: "No overview available.",
    },
    nonatomicposlookbehind: {
      title: "Non-atomic Positive lookbehind",
      detail: "No overview available.",
    },

    scriptrun: {
      title: "Script run",
      detail: "No overview available.",
    },
    atomicscriptrun: {
      title: "Atomic script run",
      detail: "No overview available.",
    },
    changematchingoptions: {
      title: "Change matching options",
      detail: "No overview available.",
    },
  },

  quants: {
    label: "Quantifiers & Alternation",
    desc:
      "Quantifiers indicate that the preceding token must be matched a certain number of times. By default, quantifiers are greedy, and will match as many characters as possible." +
      "<hr/>Alternation acts like a boolean OR, matching one sequence or another.",

    plus: {
      title: "Plus",
      detail: "Matches 1 or more of the preceding token.",
    },
    star: {
      title: "Star",
      detail: "Matches 0 or more of the preceding token.",
    },
    quant: {
      title: "Quantifier",
      detail: "Match {{getQuant()}} of the preceding token.",
    },
    opt: {
      title: "Optional",
      detail:
        "Matches 0 or 1 of the preceding token, effectively making it optional.",
    },
    lazy: {
      title: "Lazy",
      detail:
        "Makes the preceding quantifier {{getLazy()}}, causing it to match as {{getLazyFew()}} characters as possible.",
    },
    possessive: {
      title: "Possessive",
      detail:
        "Makes the preceding quantifier possessive. It will match as many characters as possible, and will not release them to match subsequent tokens.",
    },
    alt: {
      title: "Alternation",
      detail:
        "Acts like a boolean OR. Matches the expression before or after the <code>|</code>.",
    },
  },

  other: {
    label: "Special",
    desc: "Tokens that don't quite fit anywhere else.",

    comment: {
      title: "Comment",
      detail:
        "Allows you to insert a comment into your expression that is ignored when finding a match.",
    },
    conditional: {
      title: "Conditional",
      detail:
        "Conditionally matches one of two options based on whether a lookaround is matched.",
    },
    conditionalgroup: {
      title: "Group conditional",
      detail:
        "Conditionally matches one of two options based on whether group '{{name}}' matched.",
    },
    recursion: {
      title: "Recursion",
      detail:
        "Attempts to match the full expression again at the current position.",
    },
    mode: {
      title: "Mode modifier",
      detail: "{{~getDesc()}}{{~getModes()}}",
    },

    interpolation: {
      title: "Interpolation",
      detail: "No overview available.",
    },
  },

  subst: {
    label: "Substitution",
    desc: "These tokens are used in a substitution string to insert different parts of the match.",

    "subst_$&match": {
      title: "Match",
      detail: "Inserts the matched text.",
    },
    subst_0match: {
      title: "Match",
      detail: "Inserts the matched text.",
    },
    subst_group: {
      title: "Capture group",
      detail: "Inserts the results of capture group #{{group.num}}.",
    },
    subst_$before: {
      title: "Before match",
      detail:
        "Inserts the portion of the source string that precedes the match.",
    },
    subst_$after: {
      title: "After match",
      detail:
        "Inserts the portion of the source string that follows the match.",
    },
    subst_$esc: {
      title: "Escaped $",
      detail: "Inserts a dollar sign character ($).",
    },
    subst_esc: {
      title: "Escaped characters",
      detail:
        "For convenience, these escaped characters are supported in the Replace string in RegExr: <code>\\n</code>, <code>\\r</code>, <code>\\t</code>, <code>\\\\</code>, and unicode escapes <code>\\uFFFF</code>. This may vary in your deploy environment.",
    },
  },

  flags: {
    label: "Flags",
    desc: "Expression flags change how the expression is interpreted. Flags follow the closing forward slash of the expression (ex. <code>/.+/igm</code> ).",

    caseinsensitive: {
      title: "Ignore case",
      detail: "Makes the whole expression case-insensitive.",
    },
    global: {
      title: "Global search",
      detail:
        "Retain the index of the last match, allowing iterative searches.",
    },
    multiline: {
      title: "Multiline",
      detail:
        "Beginning/end anchors (<b>^</b>/<b>$</b>) will match the start/end of a line.",
    },
    unicode: {
      title: "Unicode",
      detail: "Enables <code>\\x{FFFFF}</code> unicode escapes.",
    },
    sticky: {
      title: "Sticky",
      detail:
        "The expression will only match from its lastIndex position and ignores the global (<code>g</code>) flag if set.",
    },
    dotall: {
      title: "Dot all",
      detail:
        "Dot (<code>.</code>) will match any character, including newline.",
    },
    extended: {
      title: "Extended",
      detail:
        "Literal whitespace characters are ignored, except in character sets.",
    },
    ungreedy: {
      title: "Ungreedy",
      detail: "Makes quantifiers ungreedy (lazy) by default.",
    },
  },

  misc: {
    label: "Miscellaneous",
    desc: "No overview available.",

    ignorews: {
      title: "Ignored whitespace",
      detail:
        "Whitespace character ignored due to the e<b>x</b>tended flag or mode.",
    },
    extnumref: {
      title: "Numeric reference",
      detail: "Matches the results of capture group #{{group.num}}.",
    },
    char: {
      title: "Character",
      detail:
        "Matches a {{getChar()}} character (char code {{code}}). {{getInsensitive()}}",
    },
    escchar: {
      title: "Escaped character",
      detail: "Matches a {{getChar()}} character (char code {{code}}).",
    },
    open: {
      title: "Open",
      detail: "Indicates the start of a regular expression.",
    },
    close: {
      title: "Close",
      detail:
        "Indicates the end of a regular expression and the start of expression flags.",
    },
    condition: {
      title: "Condition",
      detail:
        "The lookaround to match in resolving the enclosing conditional statement. See 'conditional' in the Reference for info.",
    },
    conditionalelse: {
      title: "Conditional else",
      detail: "Delimits the 'else' portion of the conditional.",
    },

    ERROR: {
      title: "Error",
      detail:
        "Errors in the expression are underlined in red. Roll over errors for more info.",
    },
    PREG_INTERNAL_ERROR: {
      title: "Internal error",
      detail: "Internal PCRE error",
    },
    PREG_BACKTRACK_LIMIT_ERROR: {
      title: "Backtrack limit error",
      detail: "Backtrack limit was exhausted.",
    },
    PREG_RECURSION_LIMIT_ERROR: {
      title: "Recursion limit error",
      detail: "Recursion limit was exhausted",
    },
    PREG_BAD_UTF8_ERROR: {
      title: "Bad UTF8 error",
      detail: "Malformed UTF-8 data",
    },
    PREG_BAD_UTF8_OFFSET_ERROR: {
      title: "Bad UTF8 offset error",
      detail: "Malformed UTF-8 data",
    },

    any: {
      title: "Any",
      detail: "No overview available.",
    },
    assigned: {
      title: "Assigned",
      detail: "No overview available.",
    },
    ascii: {
      title: "Unicode property",
      detail: "Matches any characters in the ASCII script extension.",
    },
  },
  errors: {
    groupopen: "Unmatched opening parenthesis.",
    groupclose: "Unmatched closing parenthesis.",
    setopen: "Unmatched opening square bracket.",
    rangerev:
      "Range values reversed. Start char code is greater than end char code.",
    quanttarg: "Invalid target for quantifier.",
    quantrev: "Quantifier minimum is greater than maximum.",
    esccharopen: "Dangling backslash.",
    esccharbad: "Unrecognized or malformed escape character.",
    unicodebad: "Unrecognized unicode category or script.",
    posixcharclassbad: "Unrecognized POSIX character class.",
    posixcharclassnoset: "POSIX character class must be in a character set.",
    notsupported:
      'The "{{~getLabel()}}" feature is not supported in this flavor of RegEx.',
    fwdslash:
      "Unescaped forward slash. This may cause issues if copying/pasting this expression into code.",
    esccharbad: "Invalid escape sequence.",
    servercomm: "An error occurred while communicating with the server.",
    extraelse: "Extra else in conditional group.",
    unmatchedref: 'Reference to non-existent group "{{name}}".',
    modebad: 'Unrecognized mode flag "<code>{{errmode}}</code>".',
    badname: "Group name can not start with a digit.",
    dupname: "Duplicate group name.",
    branchreseterr:
      "<b>Branch Reset.</b> Results will be ok, but RegExr's parser does not number branch reset groups correctly. Coming soon!",
    timeout: "The expression took longer than 250ms to execute.", // TODO: can we couple this to the help content somehow?

    // warnings:
    jsfuture:
      'The "{{~getLabel()}}" feature may not be supported in all browsers.',
    infinite:
      "The expression can return empty matches, and may match infinitely in some use cases.", // TODO: can we couple this to the help content somehow?
  },

  empty: {
    empty: {
      title: "Empty",
      detail: "No overview available.",
    },
  },
};
