# Flutter Project — Claude Code Configuration

## Project Overview
This is a Flutter app. Follow the conventions below for every file you create or edit.

## Architecture
- State management: BLoC / Cubit (flutter_bloc package)
- One Cubit per feature; keep business logic out of widgets entirely
- Use repository pattern to separate data access from Cubit logic
- Prefer stateless widgets; use StatefulWidget only when local UI state is unavoidable

## Folder Structure
lib/
  features/
    <feature_name>/
      cubit/          # <Feature>Cubit + <Feature>State
      repository/     # data access, API calls
      view/           # screens and pages
      widgets/        # reusable widgets scoped to this feature
  core/
    theme/            # AppTheme, color tokens, text styles
    router/           # GoRouter or Navigator setup
    constants/        # app-wide constants
    utils/            # helpers and extensions
  shared/
    widgets/          # globally reusable widgets

## Naming Conventions
- Files: snake_case (e.g. home_cubit.dart, user_repository.dart)
- Classes: PascalCase (e.g. HomeCubit, HomeState, UserRepository)
- Cubit states: sealed classes or named subclasses ending in State
  (e.g. HomeInitial, HomeLoading, HomeLoaded, HomeError)

## Packages to Prefer
- flutter_bloc — state management
- go_router — navigation
- freezed — immutable state/model classes (with json_serializable if needed)
- dio — HTTP client
- get_it — dependency injection
- equatable — value equality in state classes

## Widget Rules
- No business logic inside widgets — emit from Cubit only
- Use BlocBuilder, BlocListener, or BlocConsumer appropriately
- Extract repeated widget trees into named widget classes (never anonymous functions returning widgets in build)
- Use const constructors wherever possible

## Code Style
- Dart 3+ null safety throughout
- Prefer explicit types over var in class members
- Keep build() methods short — extract into private methods or widgets if > 30 lines
- Write doc comments (///) on all public classes and methods
- No print() in production code; use a logger

## Design Tokens
- Define all colors, text styles, and spacing in core/theme/
- Never hardcode colors or font sizes inline in widgets
- Use Theme.of(context) to access tokens

## Testing
- Unit test every Cubit using bloc_test
- Widget test key screens
- Place tests in test/ mirroring the lib/ structure

## What NOT to do
- Do not use setState for anything that belongs in a Cubit
- Do not put API calls directly in widgets or Cubits — use repositories
- Do not create god-files; one class per file
- Do not ignore lint warnings