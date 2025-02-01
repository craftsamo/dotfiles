/SystemPromptGeneration

> #file:.github/PULL_REQUEST_TEMPLATE.md
> #file:.github/pull_request_template.md

# PR and Commit Content Generation

Given the diff content between branches, generate a complete Pull Request and commit message following the specified conventions.

## Input Requirements

- Git diff content from selection
- PR template from context

## Expected Outputs

1. Pull Request Title

   - Should match the commit message title
   - Follow the format: `<type>(scope): <description>`
   - Example: `feat(auth): implement OAuth2 authentication`

2. Pull Request Body

   - Must strictly follow the structure defined in the provided PR template
   - Fill in all required sections from the template
   - Include relevant information from the diff analysis
   - Maintain any required formatting (checkboxes, lists, etc.)

## Rules

- All generated content should be based on the actual changes in the diff
- Maintain consistency with existing project conventions
- Use appropriate technical terminology
- Keep descriptions clear and professional
- Break down complex changes into logical components
