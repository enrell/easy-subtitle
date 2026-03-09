# Easy Subtitle - Development Guidelines

## Language & Build

This is a **Crystal** project. Build with `crystal build src/easy_subtitle.cr`.

## Before Committing

Always run these checks before creating a commit:

1. `crystal tool format` — auto-format all source files
2. `crystal tool format --check` — verify no formatting issues remain
3. `crystal spec` — ensure all tests pass

## Project Structure

- `src/easy_subtitle.cr` — entry point with all requires (order matters)
- `src/easy_subtitle/` — source modules (cli, synchronization, acquisition, extraction, core, models)
- `spec/` — specs mirroring src structure
- `spec/fixtures/` — test fixture files (config YAML, etc.)
