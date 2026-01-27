# Kiro Agent Hooks - Setup Guide

> **Important**: Kiro Hooks are managed through the UI and stored as `.kiro.hook` files in `.kiro/hooks/` directory.

## 🎯 What are Agent Hooks?

Agent Hooks are intelligent automation rules that connect workspace events to AI-powered actions. They work as "if-then" logic powered by natural language AI that understands your code and context.

**Key Components:**
- **Trigger**: Event that activates the hook (file save, create, delete, or manual)
- **Action**: AI-powered instruction sent to Kiro agent

**Benefits:**
- Eliminate manual repetitive tasks
- Maintain consistency across codebase
- Proactive AI assistance (not just reactive)
- Natural language configuration
- Team collaboration via version control

## 📋 How to Create Hooks

### Method 1: Using Explorer View (Recommended)
1. Click **Kiro icon** in Activity Bar
2. Navigate to **"Agent Hooks"** section in sidebar
3. Click the **"+"** button
4. **Describe your hook** in natural language in the input field
   - Example: "When I save a Dart file, run flutter analyze"
5. Press **Enter** or click **Submit**
6. Review and adjust the auto-generated configuration
7. Click **"Create Hook"**

### Method 2: Using Command Palette
1. Press `Cmd + Shift + P` (Mac) or `Ctrl + Shift + P` (Windows/Linux)
2. Type **"Kiro: Open Kiro Hook UI"**
3. Follow the on-screen instructions

### Method 3: Manual Configuration File
Create a `.kiro.hook` file in `.kiro/hooks/` directory:
```json
{
  "title": "Flutter Analyze on Save",
  "description": "Run flutter analyze when Dart files are saved",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Run flutter analyze in the flutter_chat_app directory and report any errors or warnings."
  }
}
```

## 🎛️ Hook Configuration Options

### Trigger Types

**1. On File Save** (`onFileSave`)
- Triggers when files matching patterns are saved
- Use for: linting, formatting, testing, code generation

**2. On File Create** (`onFileCreate`)
- Triggers when new files matching patterns are created
- Use for: scaffolding, templates, boilerplate generation

**3. On File Delete** (`onFileDelete`)
- Triggers when files matching patterns are deleted
- Use for: cleanup, dependency updates, documentation sync

**4. Manual Trigger** (`manual`)
- Triggers when you click a button or run command
- Use for: on-demand tasks, complex operations, testing

### Action Types

**Agent Prompt** (`agentPrompt`)
- Sends natural language instruction to Kiro AI
- AI understands context and executes intelligently
- Can reference workspace files, patterns, and standards

### File Patterns

Use glob patterns to match files:
- `**/*.dart` - All Dart files recursively
- `lib/**/*.dart` - All Dart files in lib directory
- `lib/data/models/**/*.dart` - Only model files
- `*.{dart,yaml}` - Multiple extensions
- `src/**/*.{ts,tsx}` - TypeScript/TSX files

### Configuration Structure

```json
{
  "title": "Hook Title",
  "description": "What this hook does",
  "enabled": true,
  "trigger": {
    "type": "onFileSave | onFileCreate | onFileDelete | manual",
    "filePatterns": ["pattern1", "pattern2"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Natural language instruction for Kiro AI"
  }
}
```

## 🔧 Recommended Hooks for This Project

### 1. Flutter Analyze on Save

**Purpose**: Automatically check for errors when saving Dart files

**Natural Language Input**:
```
When I save a Dart file in flutter_chat_app, run flutter analyze and report any errors or warnings
```

**Generated Configuration**:
```json
{
  "title": "Flutter Analyze on Save",
  "description": "Run flutter analyze when Dart files are saved",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Run flutter analyze in the flutter_chat_app directory and report any errors or warnings found."
  }
}
```

---

### 2. Code Generation Reminder

**Purpose**: Remind to regenerate code after model changes

**Natural Language Input**:
```
When I save a model file in flutter_chat_app/lib/data/models, remind me to run build_runner
```

**Generated Configuration**:
```json
{
  "title": "Code Generation Reminder",
  "description": "Remind to run build_runner after model changes",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/data/models/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Model file changed. Remind the user to run: cd flutter_chat_app && dart run build_runner build --delete-conflicting-outputs"
  }
}
```

---

### 3. Auto-Update Tests

**Purpose**: Keep unit tests synchronized with code changes

**Natural Language Input**:
```
When I save a Dart file in lib/domain or lib/data, update the corresponding test file to maintain coverage
```

**Generated Configuration**:
```json
{
  "title": "Auto-Update Tests",
  "description": "Automatically update test files when source code changes",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": [
      "flutter_chat_app/lib/domain/**/*.dart",
      "flutter_chat_app/lib/data/**/*.dart"
    ]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Review the changes in this file and update the corresponding test file in the test/ directory to maintain comprehensive test coverage. Follow the existing test patterns and ensure all new functionality is tested."
  }
}
```

---

### 4. Localization Sync

**Purpose**: Keep translations synchronized across languages

**Natural Language Input**:
```
When I update the English ARB file, check if other language files need updates
```

**Generated Configuration**:
```json
{
  "title": "Localization Sync",
  "description": "Sync translations when English ARB file changes",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/l10n/app_en.arb"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "The English localization file was updated. Review the changes and suggest updates for other language files (app_vi.arb, etc.) to keep translations synchronized."
  }
}
```

---

### 5. Run All Tests (Manual)

**Purpose**: Quick button to run all Flutter tests

**Natural Language Input**:
```
Create a manual button to run all Flutter tests
```

**Generated Configuration**:
```json
{
  "title": "Run Flutter Tests",
  "description": "Run all Flutter tests",
  "enabled": true,
  "trigger": {
    "type": "manual"
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Run all Flutter tests in the flutter_chat_app directory using 'flutter test' and report the results."
  }
}
```

---

### 6. Check Dependencies (Manual)

**Purpose**: Check for outdated packages

**Natural Language Input**:
```
Create a button to check for outdated Flutter packages
```

**Generated Configuration**:
```json
{
  "title": "Check Outdated Packages",
  "description": "Check for outdated Flutter dependencies",
  "enabled": true,
  "trigger": {
    "type": "manual"
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Run 'flutter pub outdated' in flutter_chat_app and summarize which packages have updates available."
  }
}
```

---

### 7. Documentation Sync

**Purpose**: Keep documentation in sync with code changes

**Natural Language Input**:
```
When I save a repository or use case file, check if documentation needs updates
```

**Generated Configuration**:
```json
{
  "title": "Documentation Sync",
  "description": "Update documentation when code changes",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": [
      "flutter_chat_app/lib/domain/repositories/**/*.dart",
      "flutter_chat_app/lib/domain/usecases/**/*.dart"
    ]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Review the changes in this file and check if any documentation in the docs/ directory needs to be updated to reflect these changes. Suggest specific updates if needed."
  }
}
```

---

### 8. Clean Architecture Validator

**Purpose**: Ensure layer separation rules are followed

**Natural Language Input**:
```
When I save a file in the domain layer, check that it doesn't import Flutter or infrastructure packages
```

**Generated Configuration**:
```json
{
  "title": "Clean Architecture Validator",
  "description": "Validate layer separation rules",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/domain/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Check this domain layer file for violations of Clean Architecture rules: 1) No Flutter imports (package:flutter), 2) No infrastructure imports (http, sqflite, etc.), 3) Only domain entities and interfaces. Report any violations found."
  }
}
```

---

### 9. Format and Lint on Save

**Purpose**: Auto-format and lint Dart code

**Natural Language Input**:
```
When I save a Dart file, format it and check for lint issues
```

**Generated Configuration**:
```json
{
  "title": "Format and Lint on Save",
  "description": "Auto-format and lint Dart files",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["flutter_chat_app/lib/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Format this Dart file using 'dart format' and check for any lint issues. Report if any issues are found."
  }
}
```

---

### 10. Pre-Commit Checklist (Manual)

**Purpose**: Run all checks before committing

**Natural Language Input**:
```
Create a button to run all pre-commit checks
```

**Generated Configuration**:
```json
{
  "title": "Pre-Commit Checklist",
  "description": "Run all checks before committing",
  "enabled": true,
  "trigger": {
    "type": "manual"
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Run the following pre-commit checks in flutter_chat_app: 1) flutter analyze, 2) flutter test, 3) Check for print() statements, 4) Check for hardcoded strings, 5) Verify no relative imports. Report the results of each check."
  }
}
```

---

## 💡 Best Practices

### Hook Design

**Be Specific and Clear**
- Write detailed, specific prompts for better AI understanding
- Include context about your project structure and patterns
- Reference coding standards and documentation

**Example - Vague ❌**:
```
"Update tests"
```

**Example - Specific ✅**:
```
"Review the changes in this file and update the corresponding test file in the test/ directory to maintain comprehensive test coverage. Follow the existing test patterns using bloc_test and mocktail. Ensure all new functionality is tested."
```

**Start Simple**
- Begin with basic file-to-file relationships
- Test with small file sets first
- Gradually add complexity as you get comfortable

**Monitor Performance**
- Check hook execution in chat history
- Review AI responses for accuracy
- Refine prompts based on results

### File Pattern Tips

**Use Specific Patterns**:
```json
// ✅ Good - Specific
"filePatterns": ["lib/data/models/**/*.dart"]

// ❌ Too Broad - Triggers on everything
"filePatterns": ["**/*.dart"]
```

**Multiple Patterns**:
```json
"filePatterns": [
  "lib/domain/**/*.dart",
  "lib/data/**/*.dart",
  "!lib/**/*_test.dart"  // Exclude test files
]
```

**Common Patterns**:
- `**/*.dart` - All Dart files recursively
- `lib/**/*.{dart,yaml}` - Multiple extensions
- `src/**/*.ts` - TypeScript files
- `!**/test/**` - Exclude test directories

### Leverage Workspace Context

Reference project documentation in prompts:
```json
{
  "action": {
    "type": "agentPrompt",
    "prompt": "Review this file against our Clean Architecture guidelines in .kiro/steering/project-architecture.md. Check for layer separation violations and report any issues."
  }
}
```

### Team Collaboration

**Version Control**:
- Commit `.kiro/hooks/*.kiro.hook` files to git
- Share hooks with your team
- Document hook purposes in descriptions

**Standardize Workflows**:
- Create team-wide hooks for common tasks
- Maintain consistent coding standards
- Automate code review checks

**Example Team Hook**:
```json
{
  "title": "Team Code Standards Check",
  "description": "Enforce team coding standards on save",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["lib/**/*.dart"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Check this file against our team standards: 1) No print() statements, 2) Use const constructors, 3) Package imports only (no relative), 4) Proper error handling with Either<Failure, T>. Report violations."
  }
}
```

## 🔍 Managing Your Hooks

### View Active Hooks
- Look at **"Agent Hooks"** section in Kiro sidebar
- See all hooks with their status (enabled/disabled)
- Click on a hook to view/edit configuration

### Enable/Disable Hooks
- Toggle the switch next to hook name
- Hooks remain configured but won't trigger when disabled
- Useful for temporarily disabling during bulk changes

### Edit Hooks
- Click on hook in Agent Hooks panel
- Modify title, description, triggers, or prompts
- Changes apply immediately
- Or edit `.kiro/hooks/*.kiro.hook` file directly

### Delete Hooks
- Select hook in Agent Hooks panel
- Click "Delete Hook" button
- Confirm deletion (cannot be undone)
- Or delete `.kiro/hooks/*.kiro.hook` file

### Run Manual Hooks
- Click the play button next to manual hook in panel
- Or use Command Palette: `Cmd/Ctrl + Shift + P` → "Kiro: Run Hook"
- Select the hook to execute

### View Hook History
- Check chat history to see previous hook executions
- Review AI responses and actions taken
- Use for debugging and refinement

## 🐛 Troubleshooting

### Hook Not Triggering

**Check:**
- ✓ Hook is enabled (toggle switch on)
- ✓ File pattern matches your files
- ✓ Trigger type is correct
- ✓ No syntax errors in configuration

**Test:**
```bash
# Check if pattern matches
# In terminal, test glob pattern
ls flutter_chat_app/lib/**/*.dart
```

### Unexpected Results

**Solutions:**
- Simplify the prompt and test incrementally
- Add more context and specific instructions
- Reference project documentation and patterns
- Check chat history for AI reasoning

### Performance Issues

**Optimize:**
- Use specific file patterns (avoid `**/*`)
- Disable hooks during bulk operations
- Use manual triggers for heavy operations
- Avoid running tests on every save

### Debugging Steps

1. **Check Hook Status**: Verify enabled and properly configured
2. **Test File Patterns**: Ensure patterns match intended files
3. **Review Chat History**: Check for error messages
4. **Simplify Instructions**: Start basic, add complexity gradually
5. **Test Incrementally**: Test on small file sets first

## 📚 Advanced Examples

### Security Scanner
```json
{
  "title": "Security Pre-Commit Scanner",
  "description": "Scan for security issues before commit",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["**/*"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "Scan this file for security issues: 1) Hardcoded secrets/API keys, 2) SQL injection vulnerabilities, 3) XSS vulnerabilities, 4) Insecure dependencies. Report any findings."
  }
}
```

### Internationalization Helper
```json
{
  "title": "i18n Sync Helper",
  "description": "Keep translations synchronized",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["lib/l10n/app_en.arb"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "The English localization file was updated. Compare with app_vi.arb and suggest translations for any new or modified keys. Maintain consistent tone and context."
  }
}
```

### API Documentation Generator
```json
{
  "title": "API Docs Generator",
  "description": "Update API docs when endpoints change",
  "enabled": true,
  "trigger": {
    "type": "onFileSave",
    "filePatterns": ["src/modules/**/*.resolver.ts"]
  },
  "action": {
    "type": "agentPrompt",
    "prompt": "This GraphQL resolver was modified. Update the API documentation in docs/api/ to reflect the changes. Include request/response examples and any new parameters."
  }
}
```

## 🎓 Learning Resources

- [Kiro Official Docs](https://kiro.dev/docs/hooks/) - Official documentation
- [Kiro Blog](https://kiro.dev/blog/) - Tutorials and examples
- [Community Examples](https://kiro.directory/tips/hooks/) - Real-world hook examples

---

**Last Updated**: 2025-01-27
**Version**: 2.0 (Updated with official Kiro documentation)
