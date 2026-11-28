# Master RC validation

- Replayed all supplied release archives in chronological order in two isolated trees; all guarded integration steps succeeded.
- Five integrated component-manager integrity checks (digital, rain, CRT, digital session, settings) and MATRIX icon inventory passed.
- 28 existing tests passed: 5 rain, 6 CRT, 9 digital session, 8 settings.
- Three ES 3.00 shaders compiled and linked using Mesa/EGL.
- As an unprivileged user in isolated homes: dry-run, fresh source installation, repeat upgrade and upgrade from the replayed full 0.9.1 chain succeeded with --no-packages. The new bin link, icon link, active theme and doctor checks were verified. A changed monitor profile, active MATRIX theme, saved CRT preference and previous development backups survived upgrade. Unknown customized theme switcher triggered the conflict guard, leaving it unchanged.
- Package installation via apt, optional backports and Plasma package installation are not exercised in this container; the installer does not claim a tested fresh Debian desktop. No real power commands or graphical session changes were made.
- Historical per-overlay tests are retained, but not all intermediate-version fixtures are expected to pass against the consolidated tree. Real desktop validation is still required.

## RC2 installer regression
See master/test_rc2.py for the isolated alias and package-list regression test; real ThinkPad upgrade subsequently confirmed successful by user.

## Final release — 2026-11-28

User confirmed RC2 dry-run returned no conflicts and the actual upgrade completed. Earlier development live feedback is recorded in component history; no exhaustive graphical check is inferred. 1.0.0 changes only documentation, VERSION, manifest and added inventory/release tooling; the RC2 installer logic and theme files are unchanged. Newly executed release checks are recorded below. Real fresh Debian/APT, full new Plasma activation, and final 1.0.0 live upgrade remain pending.

New checks actually run for 1.0.0:

- Verified SHA256 of both RC2 archives; compared final managed signatures to RC2. Only seven existing files changed (VERSION, README, five project documents), six files added (doctor wrapper, doctor, manifest updater, three documentation files). `master/install.py` byte-identical to RC2. All theme/effect/Plasma/shared configuration files unchanged.
- 28/28 MATRIX regression test methods passed again (rain 5, CRT 6, digital session 9, settings 8). 47 Python files parsed with AST and 169 Bash scripts syntax-checked.
- `master/test_rc2.py` passed unprivileged with disposable HOME: fresh --no-packages, 24 known aliases, local package list and keybinds, upgrade, canonical modification, external and broken link rejection.
- Actual RC2 source installed into another disposable unprivileged HOME, then final 1.0.0 dry-run and upgrade; retained 24 verified aliases, local package list/keybinds, active MATRIX and saved CRT/Rain preferences. New installed doctor reported 797 matching / 26 local retained / 0 issues; repeated upgrade succeeded. Unexpected theme-switcher modification was reported by doctor without modifying the file.
- Release archives retain Unix symlinks and permissions. Source manifest inventory and tar/ZIP parity are checked at packaging; checksums are distributed separately. Earlier Mesa/EGL shader tests were not repeated because all three shader files are unchanged.

No new GUI, actual package install, power command, compositor or remote GitHub action executed. The final package itself still requires the user's live upgrade check.
