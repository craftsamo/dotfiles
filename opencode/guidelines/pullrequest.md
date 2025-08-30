# Pull Request Guidelines

## General Rules

1. The title must begin with a verb (e.g., Add xx, Fix xx, Enable xx), be within
   50 characters.

2. If [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md) or
   [pull_request_template.md](.github/pull_request_template.md) exists, complete
   the content according to that file.

2-1. If it does not exist, execute `gh pr view {pr_number} --json body` to refer
to the three most recent Pull Requests and determine the most appropriate
format.

## Create pull request

1. The title must summarize the result of `git diff {base_branch}`

2. Run `git log -n 5` to understand the language used in recent commits.

3. The body of the Pull Request should be carefully analyzed based on the
   content of `git diff {base_branch}` and written accordingly.

## Update pull request

1. Review whether the current title is consistent with the summary of the
   `git diff {base_branch}` results. If there are inconsistencies, update the
   title appropriately.

2. Carefully analyze the current body to ensure there are no discrepancies with
   the contents of `git diff {base_branch}`. If any inconsistencies are found,
   update the body accordingly.
