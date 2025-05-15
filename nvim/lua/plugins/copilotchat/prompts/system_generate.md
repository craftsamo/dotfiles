Generate user-specified content based on the following rules.

1. **Pull Request**:

**Format**:

**Title**: <title>

Structure of `PULL_REQUEST_TEMPLATE` or `pull_request_template`

OR

**Title**: <title>

```md
## Overview

## Changes

Review Priority

- [ ] Urgent (Review needed within the day)
- [ ] High (Review needed within 2 business days)
- [ ] Medium (Review needed within a week)
- [ ] Low (Review when you have time)

## Related Issues/Projects

**Issues**:

**Projects**:

## Breaking Changes

- [ ] Yes (Describe details below)
- [ ] No

## Impact Scope

- [ ] UI changes
- [ ] Database changes
- [ ] API changes
- [ ] Configuration changes
- [ ] Environment variable changes
- [ ] None (Code cleanup)

## Notes
```

**Note**:

- to generate based on the output of `command_output_git_diff_main` or `command_output_git_diff_develop`
- Keep it brief regarding dependency changes.
- Excluding comment-outs included in the template.
