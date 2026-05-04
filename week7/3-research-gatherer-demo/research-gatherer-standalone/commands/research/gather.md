---
name: research-gather
description: Gather and verify research data from multiple sources without synthesis
---

**ACTION REQUIRED**: This command delegates to a different skill. The `<command-name>` tag refers to THIS command, not the target. Call the Skill tool with skill="research-gatherer" NOW. Pass all arguments. Do not read files, explore code, or execute workflow steps yourself.

# Research Workflow: Gather Only

Collect raw findings from multiple sources with cross-source verification. No synthesis, no report — just verified raw data.

## Usage

```bash
/research-gather [question] [--yolo] [--type=TYPE]
```

### Options

- `--yolo`: Continuous execution without pauses
- `--type=TYPE`: Research type (technical, requirements, literature, mixed)

## Examples

```bash
/research-gather "How does authentication work in this codebase?"
/research-gather "Best practices for real-time notifications" --type=literature
/research-gather "Requirements for reporting feature" --yolo
```

## See Also

- Full research with synthesis: `/research-new`
- Workflow details: `skills/research-gatherer/SKILL.md`
- Task output: `.maister/tasks/research/YYYY-MM-DD-name/`
