---
inclusion: always
---

# No Unnecessary Report Files

## Rule: Update tasks.md Instead of Creating Report Files

**CRITICAL**: When working on specs, DO NOT create separate report files for task completion. Update the `tasks.md` file directly.

### ❌ NEVER DO THIS:
```
.kiro/specs/my-spec/TASK_1_COMPLETE.md
.kiro/specs/my-spec/PHASE_1_COMPLETION_REPORT.md
.kiro/specs/my-spec/PHASE_1_FINAL_REPORT.md
.kiro/specs/my-spec/IMPLEMENTATION_SUMMARY.md
.kiro/specs/my-spec/CHECKPOINT.md
```

### ✅ ALWAYS DO THIS:
Update `tasks.md` directly with:
- Mark checkboxes `[x]` for completed acceptance criteria
- Add brief notes about implementation details
- Update the Success Criteria Summary section at the bottom

**Example**:
```markdown
### Task 1.3: Convert DatabaseService to Injectable

**Acceptance Criteria**:
- [x] `DatabaseService.instance` pattern is removed
- [x] DatabaseService uses `@singleton` annotation
- [x] Constructor injection is used
- [x] All usages are updated to use DI
- [x] Tests pass
- [x] Added compatibility methods (getPerformanceStats, performHealthCheck)

**Phase 1 Status**: ✅ **COMPLETED** (2026-01-28)
- All 7 tasks completed successfully
- DI Health Score improved from 75/100 to 90/100
```

## Exceptions (When Reports ARE Allowed)

You MAY create separate documentation files ONLY when:

1. **Audit/Analysis Results** - Technical findings that need detailed documentation
   - Example: `DI_AUDIT_REPORT.md`, `PERFORMANCE_ANALYSIS.md`
   - These contain data, metrics, and analysis that don't fit in tasks.md

2. **User Explicitly Requests** - User asks for a specific report
   - Example: "Create a deployment guide"
   - Example: "Write a migration document"

3. **Spec Documentation** - Core spec files
   - `README.md` - Spec overview
   - `requirements.md` - Requirements
   - `design.md` - Design decisions
   - `tasks.md` - Task tracking

## Why This Rule Exists

1. **Single Source of Truth** - tasks.md is the authoritative task tracker
2. **Avoid Clutter** - Too many report files make the spec folder messy
3. **Easier Maintenance** - One file to update instead of many
4. **Better Tracking** - Checkboxes in tasks.md show progress clearly
5. **Less Redundancy** - Avoid duplicating information across multiple files

## What to Do Instead

### For Task Completion:
- Update acceptance criteria checkboxes in tasks.md
- Add brief implementation notes inline
- Update Success Criteria Summary section

### For Phase Completion:
- Update the "Phase X Complete When" section in tasks.md
- Add a status line with completion date
- List key achievements in 2-3 bullet points

### For Important Findings:
- If findings are task-specific: Add to task notes in tasks.md
- If findings are spec-wide: Add to design.md or create an analysis file (with good reason)

## Self-Check Before Creating a File

Ask yourself:
1. ❓ Can this information go in tasks.md? → **Use tasks.md**
2. ❓ Is this an audit/analysis with data? → **Separate file OK**
3. ❓ Did the user request this file? → **Separate file OK**
4. ❓ Is this just task completion status? → **Use tasks.md**

## Summary

**Default Action**: Update `tasks.md`  
**Exception**: Only create separate files for audits, analyses, or user requests  
**Never**: Create `*_COMPLETE.md`, `*_REPORT.md`, `*_SUMMARY.md` for task tracking

---

**Remember**: Less is more. Keep the spec folder clean and organized.
