# 🚀 START HERE - Kiro Hooks Quick Start

## 👋 Welcome!

Bạn vừa có **20 professional hooks** được cài đặt sẵn để giúp bạn code tốt hơn!

## ⚡ 3 Bước Để Bắt Đầu

### 1️⃣ Hiểu Hooks Là Gì (2 phút)

Hooks = **Trợ lý AI tự động** review code của bạn

```
Bạn edit file → Hook phát hiện → Kiro phân tích → Feedback trong chat
```

**Ví dụ:**
```
Bạn: *Edit lib/domain/entities/user.dart*
      *Thêm: import 'package:flutter/material.dart'*

Kiro: 🚨 CRITICAL: Domain Layer Violation!
      Domain layer không được import Flutter!
      
      ❌ import 'package:flutter/material.dart'
      ✅ Use pure Dart types instead
      
      Why? Domain layer phải độc lập với UI framework.
```

### 2️⃣ Test Ngay (5 phút)

**Thử hook đầu tiên:**

1. Mở file: `flutter_chat_app/lib/presentation/pages/chat/chat_page.dart`
2. Thêm dòng này: `Text('Hello World')`
3. Save file
4. Xem Kiro feedback về hardcoded string!

**Kiro sẽ nói:**
```
⚠️ Hardcoded String Detected!
Line 45: Text('Hello World')

Should use localization:
✅ Text(context.l10n.helloWorld)

Add to app_en.arb:
"helloWorld": "Hello World"
```

### 3️⃣ Đọc Docs (10 phút)

**Đọc theo thứ tự:**

1. **[INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)** (5 phút)
   - Tổng quan về 20 hooks
   - Benefits và features
   - Quick start guide

2. **[HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)** (5 phút)
   - Visual diagrams
   - Hook categories
   - Priority guide

3. **[README.md](./README.md)** (Tham khảo khi cần)
   - Complete documentation
   - Detailed patterns
   - Code examples

## 🎯 Hooks Quan Trọng Nhất

### 🔴 CRITICAL (Phải Fix Ngay)

1. **domain-layer-guard**
   - Bảo vệ domain layer
   - Ngăn Flutter imports
   - Trigger: `lib/domain/**/*.dart`

2. **security-checker**
   - Scan security issues
   - Detect credentials
   - Trigger: All files

3. **error-handling-validator**
   - Validate Either<Failure, T>
   - Proper error handling
   - Trigger: repositories, blocs

### 🟡 HIGH (Nên Fix)

4. **flutter-code-review**
   - Review Flutter code
   - Architecture compliance
   - Trigger: All Flutter files

5. **bloc-pattern-validator**
   - Validate BLoC patterns
   - Freezed usage
   - Trigger: BLoC files

## 💡 Tips Cho Người Mới

### Ngày 1-3: Làm Quen
- ✅ Để hooks chạy tự động
- ✅ Đọc feedback
- ✅ Hỏi Kiro nếu không hiểu
- ✅ Fix CRITICAL issues

### Tuần 1: Học Patterns
- ✅ Học từ code examples
- ✅ Hiểu tại sao
- ✅ Apply vào code mới
- ✅ Fix HIGH priority issues

### Tháng 1: Thành Thạo
- ✅ Tự động follow patterns
- ✅ Ít violations hơn
- ✅ Code review nhanh hơn
- ✅ Giúp teammates

## 🎓 Learning Path

### Week 1: Basics
```
Day 1: flutter-code-review
Day 2: import-organizer
Day 3: localization-enforcer
Day 4: file-size-monitor
Day 5: Review & practice
```

### Week 2: Architecture
```
Day 1: domain-layer-guard
Day 2: bloc-pattern-validator
Day 3: repository-pattern-validator
Day 4: error-handling-validator
Day 5: Review & practice
```

### Week 3: Advanced
```
Day 1: offline-first-validator
Day 2: realtime-pattern-validator
Day 3: security-checker
Day 4: performance-analyzer
Day 5: Review & practice
```

### Week 4: Mastery
```
Day 1: All hooks review
Day 2: Pre-commit validation
Day 3: Custom hooks
Day 4: Team training
Day 5: Celebrate! 🎉
```

## 🚦 Khi Thấy Feedback

### 🔴 CRITICAL
```
🚨 CRITICAL: Domain Layer Violation!
```
**Action**: Stop và fix ngay!

### 🟡 HIGH
```
⚠️ WARNING: Missing error handling
```
**Action**: Fix trước khi commit

### 🟢 MEDIUM
```
💡 SUGGESTION: Use const constructor
```
**Action**: Review và consider

### 🔵 INFO
```
ℹ️ INFO: Consider adding tests
```
**Action**: Good to know

## 🎯 Common Scenarios

### Scenario 1: Edit Domain Entity
```
File: lib/domain/entities/user.dart
Hooks: domain-layer-guard, flutter-code-review
Priority: 🔴 CRITICAL

What to expect:
- Check for Flutter imports
- Validate pure Dart types
- Check error handling
```

### Scenario 2: Edit BLoC
```
File: lib/presentation/bloc/auth/auth_bloc.dart
Hooks: bloc-pattern-validator, error-handling-validator
Priority: 🟡 HIGH

What to expect:
- Validate Freezed usage
- Check Either<Failure, T>
- Verify disposal
```

### Scenario 3: Edit UI Widget
```
File: lib/presentation/widgets/message_bubble.dart
Hooks: flutter-code-review, localization-enforcer
Priority: 🟢 MEDIUM

What to expect:
- Check const usage
- Detect hardcoded strings
- Performance suggestions
```

## 🔧 Quick Commands

### Run Pre-Commit Check
```
1. Cmd/Ctrl + Shift + P
2. "Kiro: Run Hook"
3. Select "Pre-Commit Validation"
```

### Ask Kiro About Hook
```
"Explain this hook suggestion"
"Why is this a violation?"
"Show me the correct pattern"
```

### Disable Hook Temporarily
```
Edit .kiro/hooks/hook-name.kiro.hook
Set: "enabled": false
```

## 📚 Next Steps

### Today
- [x] Read this file
- [ ] Test a hook
- [ ] Read [INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)

### This Week
- [ ] Read [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)
- [ ] Learn from feedback
- [ ] Fix violations
- [ ] Share with team

### This Month
- [ ] Master all hooks
- [ ] Customize if needed
- [ ] Train teammates
- [ ] Measure improvements

## 🎉 You're Ready!

Bạn đã sẵn sàng với:
- ✅ 20 professional hooks
- ✅ Automatic code review
- ✅ Learning system
- ✅ Best practices enforcement

**Just start coding và để hooks giúp bạn! 🚀**

---

## 🆘 Need Help?

### Quick Help
```
Ask Kiro:
- "How do hooks work?"
- "Explain this violation"
- "Show me examples"
```

### Documentation
- [INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md) - Overview
- [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md) - Visual guide
- [README.md](./README.md) - Complete docs
- [INDEX.md](./INDEX.md) - Search index

### Team
- Ask senior developers
- Share learnings
- Update docs

---

**Remember**: Hooks are here to help you learn and improve. Don't be afraid of feedback - embrace it! 💪

**Happy Coding! 🎉**
