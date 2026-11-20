#!/usr/bin/env bash
# Claude Code status line — mirrors p10k classic layout:
#   dir  git-branch  |  model  context%

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_dir="${cwd/#$home/\~}"

# Git branch (skip lock to avoid contention)
git_branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
               || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Build output with ANSI colors (terminal will dim them)
# Cyan dir, yellow git branch, blue model, green/yellow context
dir_part=$(printf '\033[36m%s\033[0m' "$short_dir")

if [ -n "$git_branch" ]; then
  git_part=$(printf ' \033[33m %s\033[0m' "$git_branch")
else
  git_part=""
fi

if [ -n "$model" ]; then
  model_part=$(printf '  \033[34m%s\033[0m' "$model")
else
  model_part=""
fi

if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct")
  if [ "$pct_int" -ge 80 ]; then
    ctx_part=$(printf '  \033[31mctx:%s%%\033[0m' "$pct_int")
  elif [ "$pct_int" -ge 50 ]; then
    ctx_part=$(printf '  \033[33mctx:%s%%\033[0m' "$pct_int")
  else
    ctx_part=$(printf '  \033[32mctx:%s%%\033[0m' "$pct_int")
  fi
else
  ctx_part=""
fi

printf '%s%s%s%s\n' "$dir_part" "$git_part" "$model_part" "$ctx_part"
