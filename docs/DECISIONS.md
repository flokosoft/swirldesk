# Decisions
- Master preintegrates the released files rather than executing old enable scripts at runtime.
- 1.0.0 final baseline after user-confirmed RC2 upgrade; no claim that fresh APT or full Plasma activation has been validated. Explicitly record outstanding live checks.
- Fresh installation defaults to Debian, generic monitor profiles, no automatic theme or Plasma changes.
- Upgrade preserves local monitor/Hyprland/shell config and runtime state. Unknown managed changes stop before file copies. No deletion of old files.
- Apt uses existing sources by default; optional --enable-backports explicitly authorizes adding official Debian 13 backports; no display-manager changes. Plasma package installation is explicit.
- No fonts, Git history, local state, backups or Python caches. Personal KVM example identifiers replaced with placeholders; home paths made portable. Historical documentation retained where relevant.

- RC2: Preserve existing regular packages/debian.txt on upgrade. Preserve only explicitly mapped, content-identical FIELD icon aliases; unexpected or changed links remain conflicts.

- Global doctor is read-only inventory, not automatic repair; existing component doctors remain responsible for live desktop diagnosis.
- Do not silently normalize symlinks or regenerate historical integration templates against the consolidated tree.
