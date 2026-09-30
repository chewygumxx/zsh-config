// vim:set expandtab shiftwidth=4 filetype=typescript:
// SPDX-License-Identifier: GPL-3.0-only

//
//
// ~chewygumxx/zsh-config.git
// ::: :/.commitlintrc.mts
//
//

import { defineConfig } from "@chewygumxx/commitlint-config";

// One scope per published package.
export default defineConfig({
    scopes: [
        {
            name: "env",
            fullName: "Environment",
            description: "Environment variables, sourced first via zsh_dirs",
        },
        {
            name: "rc",
            fullName: "RC",
            description:
                "Core interactive setup: aliases, completion, prompt, history",
        },
        {
            name: "util",
            fullName: "Utility",
            description: "Per-tool integration snippets loaded after core rc",
        },
        {
            name: "func",
            fullName: "Function",
            description: "Autoloadable Zsh functions",
        },
        {
            name: "wrap",
            fullName: "Wrapper",
            description: "Thin command wrappers/shims",
        },
        {
            name: "spec",
            fullName: "Spec",
            description: "Third-party plugin specs",
        },
        {
            name: "comp",
            fullName: "Completion",
            description: "Completion dump/cache directory",
        },
        {
            name: "claude",
            fullName: "Claude assets",
            description: "Claude Code assets ie. hooks, skills, agents, etc.",
        },
    ],
});
