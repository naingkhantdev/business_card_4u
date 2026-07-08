# AGENTS.md

This repo uses a conservative software-engineering workflow for AI agents.

## Flutter Rules

- Do not manually create, edit, delete, or patch generated files such as `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, generated router files, or generated API files unless explicitly requested.
- Do not run `flutter analyze`, `dart analyze`, `flutter test`, `flutter run`, `flutter pub run build_runner build`, or `dart run build_runner build` unless explicitly requested.
- If code generation is needed, ask the user to run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Workflow

- Only modify source files unless explicitly requested.
- Keep edits minimal.
- Avoid unrelated formatting changes.
- Show changed file names after edits.

## Architecture Preference

```text
VO -> responses -> api -> data_agent -> data_agent_impl -> repository -> repo_provider -> goRouter -> UI
```

## Senior UI/UX Rules

When creating or changing app UI, act as a senior product designer and UI/UX architect. Screens should feel polished, modern, useful, visually engaging, and easy to understand. Avoid plain, empty, generic, or wireframe-like screens.

### Core UX Principles

- Use smart defaults. Do not make users start from blank forms when common answers are predictable. Pre-fill or pre-select the most likely option so users can scan and adjust.
- Reduce decision fatigue. Do not show too many equal choices at once. Prioritize the best option visually and label it clearly, such as `Recommended`, `Most popular`, or `Fastest setup`.
- Use goal gradient momentum. Do not make onboarding, setup, checkout, profile creation, or booking flows feel like they start at 0%. Count an action the user already completed as progress.
- Give value before asking. Do not block users with signup, payment, or long forms before showing useful value. Show a preview, result, recommendation, draft, report, or experience first.
- Build ownership early. Let users customize or create something early with minimal effort, such as choosing a theme, selecting preferences, customizing a card, picking goals, or previewing a personalized result.
- Use loss aversion honestly. For upgrades, cancellations, deletions, renewals, or exits, clearly explain the specific assets, access, history, credits, data, or progress the user may lose.
- Use contrast for pricing. Do not show prices or add-on costs alone. Provide context such as a higher plan, annual savings, original price, total project value, or included features.

### Visual Design Rules

- Make the primary action visually dominant, specific, and easy to understand.
- Use strong hierarchy, clear spacing, good contrast, selected states, progress indicators, meaningful icons, preview panels, polished cards, and helpful empty states.
- Prefer interactive choices over typing where practical: chips, toggle groups, cards, steppers, dropdowns, date/time suggestions, and recommended choices.
- Avoid weak gray primary buttons, unclear CTAs, walls of text, too many equal options, signup walls before value, and flat layouts with no visual focus.
- Replace generic CTAs like `Submit`, `Next`, `OK`, or `Click Here` with specific actions such as `Search 12 Available Tables`, `Save My Design`, `Continue Setup`, `Generate Preview`, or `Keep My Progress`.

### UI Review Checklist

Before finalizing UI work, check that the screen:

- Looks visually attractive and product-ready.
- Has one obvious primary action.
- Uses smart defaults and visible selected states.
- Reduces typing and unnecessary decisions.
- Shows progress where the user is in a flow.
- Gives useful value before asking for signup or payment.
- Lets the user customize or create something where appropriate.
- Explains specific risks or losses where relevant.
- Shows pricing with useful context where relevant.
