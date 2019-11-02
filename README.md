# Pronto runner for stylelint (using stylelint from npm)

[![Gem Version](https://badge.fury.io/rb/pronto-stylelint.svg)](http://badge.fury.io/rb/pronto-stylelint)
[![Build Status](https://travis-ci.org/kevinjalbert/pronto-stylelint.svg?branch=master)](https://travis-ci.org/kevinjalbert/pronto-stylelint)
[![Code Climate](https://codeclimate.com/github/kevinjalbert/pronto-stylelint/badges/gpa.svg)](https://codeclimate.com/github/kevinjalbert/pronto-stylelint)
[![Test Coverage](https://codeclimate.com/github/kevinjalbert/pronto-stylelint/badges/coverage.svg)](https://codeclimate.com/github/kevinjalbert/pronto-stylelint/coverage)

Pronto runner for [stylelint](http://stylelint.io), the mighty, modern CSS linter. [What is Pronto?](https://github.com/prontolabs/pronto)

Uses official stylelint executable installed by `npm`.

Heavily inspired by [doits/pronto-eslint_npm](https://github.com/doits/pronto-eslint_npm).

## Prerequisites

You'll need to install [stylelint by yourself with npm](http://stylelint.io/user-guide/cli/). If `stylelint` is in your `PATH`, everything will simply work, otherwise you have to provide pronto-stylelint your custom executable path (see [below](#configuration-of-stylelint)).

## Configuration of stylelint

Configuring stylelint via [.stylelintrc and consorts](http://stylelint.io/user-guide/configuration/#loading-the-configuration-object) and excludes via [.stylelintignore](http://stylelint.io/user-guide/configuration/#stylelintignore) will work just fine with pronto-stylelint.

## Configuration of pronto-stylelint

pronto-stylelint can be configured by placing a `.pronto_stylelint.yml` inside the directory where pronto is run.

Following options are available:

| Option               | Meaning                                                                                  | Default                                   |
| -------------------- | ---------------------------------------------------------------------------------------- | ----------------------------------------- |
| stylelint_executable | stylelint executable to call.                                                            | `stylelint` (calls `stylelint` in `PATH`) |
| files_to_lint        | What files to lint. Absolute path of offending file will be matched against this Regexp. | `\.(c\|sc\|sa\|le)ss$`                    |
| cli_options          | Options to pass to the CLI.                                                              | `-f json`                                 |

Example configuration to call custom stylelint executable and specify custom options:

```yaml
# .pronto_stylelint.yml
stylelint_executable: '/my/custom/node/path/.bin/stylelint'
files_to_lint: '\.(c|sc)ss$'
cli_options: '--config /custom/stylelintrc'
```
