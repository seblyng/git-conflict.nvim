# Changelog

## [2.0.0](https://github.com/seblj/git-conflict.nvim/compare/v1.3.0...v2.0.0) (2024-06-03)


### ⚠ BREAKING CHANGES

* nightly has renamed the user command creation function this commit adopts the new api. Please update your neovim or this will break. Apologies for the inconvenience

### Features

* Add `GitConflictRefresh` ([#24](https://github.com/seblj/git-conflict.nvim/issues/24)) ([e07a02a](https://github.com/seblj/git-conflict.nvim/commit/e07a02ae1436d4c5d33ef656310d630d19e0a65b))
* add a command to display conflicts in qf. ([#4](https://github.com/seblj/git-conflict.nvim/issues/4)) ([b726df0](https://github.com/seblj/git-conflict.nvim/commit/b726df0d3b1129b88edcb0ee74fdd6b7babf7af5))
* Add a list_opener setting ([#63](https://github.com/seblj/git-conflict.nvim/issues/63)) ([1e74b7d](https://github.com/seblj/git-conflict.nvim/commit/1e74b7dd6c1b4c6750e6f917f91012c450aece86))
* add ability to select a section to keep ([b85b88e](https://github.com/seblj/git-conflict.nvim/commit/b85b88ea8c256cca88aeb791b5e0e8d4a7dd504b))
* add ability to toggle buffer diagnostics ([a60192b](https://github.com/seblj/git-conflict.nvim/commit/a60192bf29f808fc74828319d63bc31e30d8118b))
* add commands for hunk actions ([d9a9f58](https://github.com/seblj/git-conflict.nvim/commit/d9a9f5883e1d4ace31680b274926fce010d1f985))
* add commands for hunk navigation ([e9025a4](https://github.com/seblj/git-conflict.nvim/commit/e9025a42ffaed6bab9c414368fb0bf9d7ca41ec2))
* add default mappings ([5edcc1b](https://github.com/seblj/git-conflict.nvim/commit/5edcc1b0a1da17b57fd4e2fc16249187c14f0195))
* add keymap descriptions. ([#23](https://github.com/seblj/git-conflict.nvim/issues/23)) ([a8abdc5](https://github.com/seblj/git-conflict.nvim/commit/a8abdc59603516e1d45eb78d511efa40c6035bdc))
* add option to disable commands ([#35](https://github.com/seblj/git-conflict.nvim/issues/35)) ([77faa75](https://github.com/seblj/git-conflict.nvim/commit/77faa75c09a6af88e7b54d8d456327e06611f7ea))
* add support for accepting "none" ([4bee7c2](https://github.com/seblj/git-conflict.nvim/commit/4bee7c2e0023d2245fc54410af17bcbc92e39463))
* add support for git worktrees ([#81](https://github.com/seblj/git-conflict.nvim/issues/81)) ([1371080](https://github.com/seblj/git-conflict.nvim/commit/13710803346cfe468ce7be250d19c430866ba1bd))
* **api:** add conflict_count function ([#75](https://github.com/seblj/git-conflict.nvim/issues/75)) ([599d380](https://github.com/seblj/git-conflict.nvim/commit/599d3809ea3bf1ef26c8368bfc74c50c44f39913))
* initial commit ([7227945](https://github.com/seblj/git-conflict.nvim/commit/722794536dcb44e07a96586cdeb588f72e4e5729))
* make label text bold ([b1b40c1](https://github.com/seblj/git-conflict.nvim/commit/b1b40c1310568777631a2273e006ce1c27975cd2))
* setup plug mappings a user can override ([8bf94d9](https://github.com/seblj/git-conflict.nvim/commit/8bf94d978892efc62ac721ade5568fd5113971bd))
* support diff3 conflict style ([#3](https://github.com/seblj/git-conflict.nvim/issues/3)) ([c151651](https://github.com/seblj/git-conflict.nvim/commit/c151651cd046e9afb344cccb62f47b87300382d5))
* throttle BufEnter git fetch ([48e0485](https://github.com/seblj/git-conflict.nvim/commit/48e0485e67633b4c42b12fd520d4302ad75daadb))
* user mappings config ([#42](https://github.com/seblj/git-conflict.nvim/issues/42)) ([c92604a](https://github.com/seblj/git-conflict.nvim/commit/c92604a64a2cce15a6e6a753f4501bcee06fa00a))


### Bug Fixes

* add functions to navigate to conflicts ([115b139](https://github.com/seblj/git-conflict.nvim/commit/115b13942daccec2857ac75c24e6a3a191c8af6d))
* allow navigating only to ours or theirs ([696f161](https://github.com/seblj/git-conflict.nvim/commit/696f161f965c7aba82acadbb93ab944438712f9d))
* change autocommand condition for Detected/Resolved ([de3345e](https://github.com/seblj/git-conflict.nvim/commit/de3345e3daef27147d48308f889b7fd90c42ddfb))
* check buffer is valid before clearing namespace ([fed0771](https://github.com/seblj/git-conflict.nvim/commit/fed0771d6cbb78d386d7a28b63c6a608d698b4cc))
* check buffer is valid before using it ([e41555b](https://github.com/seblj/git-conflict.nvim/commit/e41555bf0be8a06589b5a7598220e33962333feb)), closes [#50](https://github.com/seblj/git-conflict.nvim/issues/50)
* clear buffer mappings on conflict resolved ([a185ffb](https://github.com/seblj/git-conflict.nvim/commit/a185ffb0cd3e278df392cbc2af821d0a64c25011))
* clear extmark if conflict is invalid ([#12](https://github.com/seblj/git-conflict.nvim/issues/12)) ([8f55c1a](https://github.com/seblj/git-conflict.nvim/commit/8f55c1ab096934dba9e3581eaf9c3e7e24215bc7))
* clear old extmarks in un-conflicted buffers ([6712e65](https://github.com/seblj/git-conflict.nvim/commit/6712e655812e04647885440d81498bc6003d72b3))
* **color:** add fallback color ([#6](https://github.com/seblj/git-conflict.nvim/issues/6)) ([0fcfc38](https://github.com/seblj/git-conflict.nvim/commit/0fcfc38eabeae3a338a7ac5478436b5b408e4878))
* **color:** reset the color after colorscheme was changed ([#39](https://github.com/seblj/git-conflict.nvim/issues/39)) ([#40](https://github.com/seblj/git-conflict.nvim/issues/40)) ([cbefa70](https://github.com/seblj/git-conflict.nvim/commit/cbefa7075b67903ca27f6eefdc9c1bf0c4881017))
* ensure valid value is passed when opening QF ([2957f74](https://github.com/seblj/git-conflict.nvim/commit/2957f747e1a34f1854e4e0efbfbfa59a1db04af5))
* extmarks missing from final line ([#87](https://github.com/seblj/git-conflict.nvim/issues/87)) ([96458b8](https://github.com/seblj/git-conflict.nvim/commit/96458b843795c6dd84f221188cccd3242328349e))
* fix condition to create autocmd ([fdb772a](https://github.com/seblj/git-conflict.nvim/commit/fdb772ac0357ca873ada25865d7a1b9ce94af7fd))
* highlights should be default ([75e9056](https://github.com/seblj/git-conflict.nvim/commit/75e90560521e5e395452e9a9f36309ae8f6000a7))
* ignore empty ancestor positions ([4eadebf](https://github.com/seblj/git-conflict.nvim/commit/4eadebf4cafff19e96a8a43aa25e6be47f465dbe)), closes [#8](https://github.com/seblj/git-conflict.nvim/issues/8)
* improve check for visited buffer when populating qf ([#16](https://github.com/seblj/git-conflict.nvim/issues/16)) ([8b7ce88](https://github.com/seblj/git-conflict.nvim/commit/8b7ce8839e2aaa847d2d2f2dca0e8e2f62f1d356))
* in order conflict traversal ([179f073](https://github.com/seblj/git-conflict.nvim/commit/179f073c7abb60b851c0d36ce0df61b111b2bb67))
* **mappings:** set mappings if needed when parsing buffer ([#66](https://github.com/seblj/git-conflict.nvim/issues/66)) ([b1c1274](https://github.com/seblj/git-conflict.nvim/commit/b1c1274873f0b9a1b8da7eac62bb74c9266d4410))
* nest plugin files in lua directory ([bba0f1b](https://github.com/seblj/git-conflict.nvim/commit/bba0f1be2887a24cf29f9a3832b2b0de1b050d16))
* off-by-one error in find_position ([#86](https://github.com/seblj/git-conflict.nvim/issues/86)) ([4ff00ae](https://github.com/seblj/git-conflict.nvim/commit/4ff00aed1ef47d9b7ab16ca62563089c15723b14))
* **qf:** don't try adding items for resolved conflicts ([b1c434c](https://github.com/seblj/git-conflict.nvim/commit/b1c434c93d19910ac4dd699a2ea71f8e8182d352))
* **quickfix cmd:** construct items from visited buffers ([#68](https://github.com/seblj/git-conflict.nvim/issues/68)) ([cee519e](https://github.com/seblj/git-conflict.nvim/commit/cee519ef0482b20e506ae1401f82f3c7b23a6c03))
* **quickfix:** invoke callback once with all items ([#70](https://github.com/seblj/git-conflict.nvim/issues/70)) ([a97a355](https://github.com/seblj/git-conflict.nvim/commit/a97a35507a485d6bbdc3c67820a8ca459c9c3f49))
* refactor autocommand to use buffer's directory ([b79dc7d](https://github.com/seblj/git-conflict.nvim/commit/b79dc7dae89d4436ce55ebbbebadf1f6ada8a8d2))
* remove extmarks for conflict labels ([37f27f2](https://github.com/seblj/git-conflict.nvim/commit/37f27f2bac977b9aefc517eb8898333a184f6a67))
* reset visited_buffers state on git diff ([a8ef136](https://github.com/seblj/git-conflict.nvim/commit/a8ef136a0e170de7d3f00f87722933a2039c0cd7))
* Reverse hl groups and adjust shade ([#20](https://github.com/seblj/git-conflict.nvim/issues/20)) ([000548d](https://github.com/seblj/git-conflict.nvim/commit/000548d5cc54931e88694c737fb8105d8781ab57))
* swap mappings for next/prev conflict ([c3230fd](https://github.com/seblj/git-conflict.nvim/commit/c3230fd0322b3d8e47b85478251f83d4587bdca5))
* throttle checking conflicted files ([#7](https://github.com/seblj/git-conflict.nvim/issues/7)) ([0163777](https://github.com/seblj/git-conflict.nvim/commit/0163777c4174e504013a7e14998a5978e93c40f0))
* use a list for jobstart [#58](https://github.com/seblj/git-conflict.nvim/issues/58) ([#59](https://github.com/seblj/git-conflict.nvim/issues/59)) ([751d98b](https://github.com/seblj/git-conflict.nvim/commit/751d98be83a9c7bdf0a136d05d8b7b1c25560368))
* use actual line content to show section labels ([6314f8a](https://github.com/seblj/git-conflict.nvim/commit/6314f8a379f8c67b9bbb76ad50950bdb4b72fd65))
* use correct ranges for content replacement ([5e62fc9](https://github.com/seblj/git-conflict.nvim/commit/5e62fc9959afe478196bf54a347b610c9a625c03))
* use nvim_exec_autocmd ([#5](https://github.com/seblj/git-conflict.nvim/issues/5)) ([ca26a3b](https://github.com/seblj/git-conflict.nvim/commit/ca26a3b40318251476f7879d12ac01cafaa34ecd))
* use nvim_exec_autocmds after rename on nightly ([#9](https://github.com/seblj/git-conflict.nvim/issues/9)) ([9246035](https://github.com/seblj/git-conflict.nvim/commit/924603597b7a244e08a92129d6af764e18ce089a))


### Reverts

* key visited buffers by name ([fdcb948](https://github.com/seblj/git-conflict.nvim/commit/fdcb9487da6da4ccdfe17a2702c19734a0f1e3a5))


### Code Refactoring

* use nvim_create_user_command ([fb6085d](https://github.com/seblj/git-conflict.nvim/commit/fb6085d0f90a2e417d237dac0bce50b180d200c2))

## [1.3.0](https://github.com/akinsho/git-conflict.nvim/compare/v1.2.2...v1.3.0) (2024-01-22)


### Features

* **api:** add conflict_count function ([#75](https://github.com/akinsho/git-conflict.nvim/issues/75)) ([599d380](https://github.com/akinsho/git-conflict.nvim/commit/599d3809ea3bf1ef26c8368bfc74c50c44f39913))

## [1.2.2](https://github.com/akinsho/git-conflict.nvim/compare/v1.2.1...v1.2.2) (2023-09-17)


### Bug Fixes

* **quickfix:** invoke callback once with all items ([#70](https://github.com/akinsho/git-conflict.nvim/issues/70)) ([a97a355](https://github.com/akinsho/git-conflict.nvim/commit/a97a35507a485d6bbdc3c67820a8ca459c9c3f49))

## [1.2.1](https://github.com/akinsho/git-conflict.nvim/compare/v1.2.0...v1.2.1) (2023-08-31)


### Bug Fixes

* **mappings:** set mappings if needed when parsing buffer ([#66](https://github.com/akinsho/git-conflict.nvim/issues/66)) ([b1c1274](https://github.com/akinsho/git-conflict.nvim/commit/b1c1274873f0b9a1b8da7eac62bb74c9266d4410))
* **quickfix cmd:** construct items from visited buffers ([#68](https://github.com/akinsho/git-conflict.nvim/issues/68)) ([cee519e](https://github.com/akinsho/git-conflict.nvim/commit/cee519ef0482b20e506ae1401f82f3c7b23a6c03))

## [1.2.0](https://github.com/akinsho/git-conflict.nvim/compare/v1.1.2...v1.2.0) (2023-08-21)


### Features

* Add a list_opener setting ([#63](https://github.com/akinsho/git-conflict.nvim/issues/63)) ([1e74b7d](https://github.com/akinsho/git-conflict.nvim/commit/1e74b7dd6c1b4c6750e6f917f91012c450aece86))


### Bug Fixes

* use a list for jobstart [#58](https://github.com/akinsho/git-conflict.nvim/issues/58) ([#59](https://github.com/akinsho/git-conflict.nvim/issues/59)) ([751d98b](https://github.com/akinsho/git-conflict.nvim/commit/751d98be83a9c7bdf0a136d05d8b7b1c25560368))

## [1.1.2](https://github.com/akinsho/git-conflict.nvim/compare/v1.1.1...v1.1.2) (2023-04-26)


### Bug Fixes

* highlights should be default ([75e9056](https://github.com/akinsho/git-conflict.nvim/commit/75e90560521e5e395452e9a9f36309ae8f6000a7))

## [1.1.1](https://github.com/akinsho/git-conflict.nvim/compare/v1.1.0...v1.1.1) (2023-04-26)


### Bug Fixes

* check buffer is valid before using it ([e41555b](https://github.com/akinsho/git-conflict.nvim/commit/e41555bf0be8a06589b5a7598220e33962333feb)), closes [#50](https://github.com/akinsho/git-conflict.nvim/issues/50)

## [1.1.0](https://github.com/akinsho/git-conflict.nvim/compare/v1.0.0...v1.1.0) (2023-04-18)


### Features

* add option to disable commands ([#35](https://github.com/akinsho/git-conflict.nvim/issues/35)) ([77faa75](https://github.com/akinsho/git-conflict.nvim/commit/77faa75c09a6af88e7b54d8d456327e06611f7ea))
* user mappings config ([#42](https://github.com/akinsho/git-conflict.nvim/issues/42)) ([c92604a](https://github.com/akinsho/git-conflict.nvim/commit/c92604a64a2cce15a6e6a753f4501bcee06fa00a))


### Bug Fixes

* **color:** reset the color after colorscheme was changed ([#39](https://github.com/akinsho/git-conflict.nvim/issues/39)) ([#40](https://github.com/akinsho/git-conflict.nvim/issues/40)) ([cbefa70](https://github.com/akinsho/git-conflict.nvim/commit/cbefa7075b67903ca27f6eefdc9c1bf0c4881017))
* ensure valid value is passed when opening QF ([2957f74](https://github.com/akinsho/git-conflict.nvim/commit/2957f747e1a34f1854e4e0efbfbfa59a1db04af5))
