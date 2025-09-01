# AGENTS

## General Rules

1. The session title must begin with a verb (e.g., Add xx, Fix xx, Enable xx),
   be within 30 characters.

## Multi-Agent Workflow System

This OpenCode configuration includes a comprehensive multi-agent workflow system
that enables parallel execution with real-time progress tracking and intelligent
coordination.

### Available Agents

#### Core System Agents

- **@assistant**: Main coordinator managing agent communication, workflow, and
  direct implementation
- **@planner**: Analyzes requests and creates detailed execution plans
- **@todo-manager**: Manages real-time todo updates and progress tracking

#### Specialized Domain Agents

- **@searcher**: Research, documentation analysis, information gathering
- **@ui-designer**: UI/UX design, wireframes, component specifications
- **@frontend-engineer**: Frontend development, JavaScript, CSS, HTML
- **@backend-engineer**: Backend development, APIs, databases, infrastructure
- **@fullstack-engineer**: Full-stack development covering both frontend and
  backend
- **@tester**: Test creation, execution, and quality assurance
- **@documentation-engineer**: Documentation creation and maintenance

### Usage Examples

#### Simple Request

```
User: "Fix the CSS styling in header component"
→ @frontend-engineer handles directly
```

#### Complex Multi-Agent Workflow

```
User: "Build an e-commerce platform"
→ @assistant coordinates:
   ├── @planner (execution plan)
   ├── @searcher (market research)
   ├── @ui-designer (shopping flow design)
   ├── @backend-engineer (API services and database)
   └── @frontend-engineer (catalog implementation)
```

### Real-Time Progress Tracking

The system provides live updates during complex workflows:

```
## 🔄 Live Progress Update

**Overall**: 65% complete (13/20 tasks)
**Active**: 3 agents working

### Current Activity
🔄 @frontend-engineer → Component implementation (80% done)
🔄 @ui-designer → Design system finalization (45% done)
✅ @searcher → Research complete

**Updated**: 1 minute ago
```
