# my-ai-ide

My IDE in the AI era isn't an editor. It has three parts:

- a workspace where coding agents run side by side;
- plugins and skills that tell those agents how to work;
- one private repo that puts all of it on a new machine with `git clone` and `./install.sh`.

This repo is the public version: the idea, what I use, and the parts I wrote
myself. My private repo (`astack`) holds the full setup.

## The layers

| Layer | What I use | What it does |
|---|---|---|
| Workspace | [T3 Code](https://github.com/pingdotgg/t3code) | Threads, git worktrees, subagents on several providers, scheduled tasks, PR tracking |
| Terminal | [scripts](https://github.com/Anmolnoor/scripts): zsh, Oh My Zsh, Powerlevel10k, MesloLGS NF fonts | The prompt, plugins and git shortcuts, including `sum`/`cws`, which have Claude write the commit message for staged changes |
| Agents | Claude Code, Codex | Write, review and ship code |
| Process | [SoloFounder](https://github.com/solofounder-ai/solofounder) plugin | Turns every request into a short flow of stages with review gates |
| Coding style | [Ponytail](https://github.com/DietrichGebert/ponytail) plugin, Karpathy-style guidelines | Smallest working change; think first, surgical diffs, verify |
| Roles | 10x-Team plugin | Product, architecture, security and QA checklists during planning and testing |
| Platform | Vercel plugin | Deploys, env vars, current platform docs |
| Knowledge work | Anthropic's engineering and design plugins; docs, pdf, xlsx, pptx and deep-research skills | Code review, system design, documents |
| Shipping | tstack skills: file-pr, babysit-pr, full-send, full-stop, council, sol-loop, takeover, modernize, leaving-pr-comments | The PR lifecycle, plus review by more than one model |
| My own skills | tdd, debugging, rfc, api-design, db-migrations, react-bits ([`skills/`](skills)) | Hard gates: no code before a failing test, no fix before a repro, no endpoint before its contract |

## The rules that tie it together

These live in my global `CLAUDE.md`:

- **Think before coding.** State assumptions, ask when unclear, write the
  least code that works, touch only what the task needs, and define how
  you'll verify it before you start.
- **SoloFounder by default, Ponytail only while coding.** SoloFounder runs
  the flow (planning, research, review, writing, PRs). Ponytail runs only
  in the stages that write code.
- **Full send by default.** A task that opens a PR goes end to end and
  merges once the gate passes. Saying "full stop" leaves the PR ready but
  unmerged.
- **More than one model for decisions.** `council` asks three models from
  two providers. `sol-loop` has a second model review the change for a few
  rounds, stopping early once only nits are left.
- **Two machines.** A fast Mac does the coding and review work. A Linux laptop
  does merges, final test runs and Linux-only checks. Each agent gets its own
  checkout, and each machine runs one full test suite at a time.
- **Learn on the way.** When a concept worth knowing comes up, the agent
  offers to explain it once and logs it to a learning list.

## Keeping the stack current

- `~/.claude` is symlinked into the private repo, so every file there is
  live and versioned.
- `stack.lock.json` records the stack: marketplaces, plugin versions and
  commits, skills, agents, and what syncs from the Claude account.
  [`bin/astack-snapshot`](bin/astack-snapshot) writes it, `--check` fails on
  drift, and `--upgrades` lists newer plugin versions. It expects the
  private repo's layout (`claude/skills`, `claude/agents`).
- A weekly scheduled task records drift, lists upgrades, and opens one PR.
  It asks council only when there's a real decision, such as two skills
  that overlap or a breaking upgrade. I review every stack change before
  merging.
- On a new machine: clone, run `install.sh`. It links the files, installs
  every plugin in the lock, and sets up the terminal from `scripts`.

## In this repo

- [`skills/`](skills): the skills I wrote. Drop a folder into `~/.claude/skills/`.
- [`bin/astack-snapshot`](bin/astack-snapshot): the lockfile script.
- [`bin/agent-stats`](bin/agent-stats): PRs, agent sessions, hours, tokens,
  crashes and machine health for the last 24 hours and 7 days. `--with HOST`
  adds another machine over ssh; `--json` prints one line per machine for a
  daily log.
- [`statusline-command.sh`](statusline-command.sh): a status line showing
  directory, git branch, model and context use.

Third-party skills and plugins aren't copied here. Get them from their own
repos.
