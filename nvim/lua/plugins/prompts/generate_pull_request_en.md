/SystemPromptGeneration

> #file:.github/PULL_REQUEST_TEMPLATE.md
> #file:.github/pull_request_template.md

# PR Content Generation

Given the diff content between branches, generate a complete Pull Request and Pull Request title following the specified conventions.

## Input Requirements

- Git diff content from selection
- PR template from context

## Expected Outputs

Generate the following sections in order:

### Required Format

```
# Pull Request Title
<Your generated title here>

# Pull Request Body
<Your generated PR body here>
```

1. Pull Request Title

   - Should clearly describe the purpose and scope of all changes
   - Use natural, descriptive language
   - Length should be concise but informative (recommended max 72 characters)
   - Must accurately represent the collective changes in the PR

   Examples:

   - `Add user authentication with OAuth2`
   - `Refactor data processing pipeline for better performance`
   - `Update user profile UI and add settings management`
   - `Fix critical security vulnerability in login system`

   Guidelines:

   - Be specific about what is being changed
   - Start with a verb in present tense
   - Avoid unnecessary technical details
   - Include scope/area if helpful for clarity
   - Consider adding priority markers if needed (e.g., [URGENT], [BREAKING])

2. Pull Request Body
   - Must strictly follow the structure defined in the provided PR template
   - Fill in all required sections from the template
   - Include relevant information from the diff analysis
   - Maintain any required formatting (checkboxes, lists, etc.)
   - Omit commenting out
   - Break down complex changes into clear, logical sections
   - Include any important technical details omitted from the title
   - Reference related issues or dependencies if applicable
   - Highlight any breaking changes or important considerations

Important: Both title and body sections are required in the output. Always start with the title section followed by the body section.
