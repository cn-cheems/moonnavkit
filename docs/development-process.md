# Development Process

MoonNavKit is developed around the public repository. Each meaningful change
should be traceable through an issue, a commit or pull request, and a changelog
entry when user-visible behavior changes.

## Work Items

- Use GitHub issues for bugs, feature requests, and performance tasks.
- Keep issue titles short and specific.
- Link commits or pull requests back to the related issue when possible.
- Record reproduction cases for bugs with a minimal grid or graph example.

## Commits

- Keep commits focused on one coherent change.
- Prefer messages that describe the result, such as `Use priority queue for grid search`.
- Run `moon check` and `moon test` before pushing changes that affect code.
- Avoid mixing personal submission material with public repository commits.

## Pull Requests

- Use the repository pull request template.
- Include the related issue when one exists.
- List verification commands and update tests for behavior changes.
- Update `CHANGELOG.md` for public API, algorithm, export, or documentation milestones.

## Changelog

- Use `CHANGELOG.md` to summarize visible changes.
- Group entries by date and version-like milestone.
- Keep the wording factual: added, changed, fixed, verified.
- Record test counts when a milestone is prepared for contest review.

## Contest Review Checklist

- Public GitHub repository is up to date.
- GitLink import points to the latest GitHub commit.
- Commit count stays above the contest threshold.
- Issues, pull requests, and changelog entries explain the work history.
- `moon check` and `moon test` pass before final submission.

