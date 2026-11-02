// vim:set expandtab shiftwidth=4 filetype=typescript:
// SPDX-License-Identifier: GPL-3.0-only

//
//
// ~chewygumxx/zsh-config.git
// ::: :/.commitlintrc.mts
//
//

import { defineConfig } from "@chewygumxx/commitlint-config";

const scopes = [
    {
        name: "env",
        fullName: "Zshenv",
        description: "Universal Initialisation",
    },
    {
        name: "rc",
        fullName: "Zshrc",
        description: "Interactive Initialisation",
    },
    {
        name: "util",
        fullName: "Utility",
        description: "Tool-Specific Integration",
    },
    {
        name: "func",
        fullName: "Function",
        description: "Autoload-ed function files (excluding wrappers)",
    },
    {
        name: "wrap",
        fullName: "Wrapper",
        description: "Autoload-ed function files as command wrappers",
    },
    {
        name: "spec",
        fullName: "Plugin Spec",
        description: "Third-party plugin specification",
    },
    {
        name: "comp",
        fullName: "Completion",
        description: "Completion function files",
    },
];

export default defineConfig({
    scopes: scopes,
});
