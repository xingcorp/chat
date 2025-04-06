# Git Workflow

## Tổng quan

Tài liệu này mô tả quy trình làm việc với Git được áp dụng trong dự án chat app để đảm bảo tính nhất quán, dễ theo dõi lịch sử phát triển và tạo điều kiện thuận lợi cho việc hợp tác giữa các thành viên trong nhóm phát triển.

## Mô hình phân nhánh

Dự án sử dụng mô hình phân nhánh GitFlow với một số điều chỉnh cho phù hợp với quy trình phát triển của nhóm.

### Các nhánh chính

- **main**: Nhánh chính chứa code sẵn sàng cho production. Mọi code trên nhánh này phải hoạt động ổn định và được kiểm thử kỹ lưỡng.
- **develop**: Nhánh phát triển chính, chứa code mới nhất đã được merge và đang trong quá trình chuẩn bị cho phiên bản tiếp theo.

### Các nhánh phụ

- **feature/\***: Dùng để phát triển tính năng mới, sẽ được merge vào nhánh `develop`.
- **bugfix/\***: Dùng để sửa lỗi trong quá trình phát triển, sẽ được merge vào nhánh `develop`.
- **hotfix/\***: Dùng để sửa lỗi khẩn cấp trên production, sẽ được merge vào cả `main` và `develop`.
- **release/\***: Dùng để chuẩn bị cho phiên bản mới, bao gồm các tác vụ cuối cùng như cập nhật version, sửa các lỗi nhỏ, sẽ được merge vào `main` và `develop`.

## Quy tắc đặt tên nhánh

### Format chung
```
<loại>/<mã-task>-<mô-tả-ngắn>
```

Ví dụ:
- `feature/CHAT-123-implement-hero-animations`
- `bugfix/CHAT-456-fix-message-sync-issue`
- `hotfix/CHAT-789-crash-on-attachment-upload`
- `release/v1.2.0`

### Quy tắc đặt tên:
- Sử dụng chữ thường và dấu gạch ngang (`-`) để ngăn cách các từ
- Bắt đầu với loại nhánh (feature, bugfix, hotfix, release)
- Bao gồm mã task từ hệ thống quản lý dự án (JIRA, Trello, etc.)
- Mô tả ngắn gọn, rõ ràng về nội dung công việc
- Hạn chế độ dài của tên nhánh (tối đa 50 ký tự)

## Luồng làm việc

### Tạo nhánh mới
```bash
# Checkout nhánh develop mới nhất
git checkout develop
git pull origin develop

# Tạo nhánh feature mới
git checkout -b feature/CHAT-123-implement-hero-animations
```

### Commit code
```bash
# Thêm các thay đổi vào staging
git add <files>

# Commit với message rõ ràng
git commit -m "CHAT-123: Implement hero animations for avatars"
```

### Push code lên remote
```bash
git push origin feature/CHAT-123-implement-hero-animations
```

### Tạo Pull Request (PR)

1. Tạo PR từ nhánh feature vào nhánh develop trên GitHub/GitLab/BitBucket
2. Điền thông tin theo template PR có sẵn
3. Gán reviewer là những người có kinh nghiệm với phần code đang thay đổi
4. Chờ ít nhất 1 approval trước khi merge

### Merge code

Sau khi PR được approve, có hai cách để merge code:

1. **Squash and merge**: Gộp tất cả các commit thành một commit duy nhất (khuyến nghị cho các nhánh feature)
2. **Merge commit**: Giữ nguyên lịch sử commit (khuyến nghị cho các nhánh release và hotfix)

## Quy tắc commit message

### Format
```
<loại>(<phạm-vi>): <mô-tả>

[phần thân]

[phần footer]
```

### Loại commit
- **feat**: Tính năng mới
- **fix**: Sửa lỗi
- **docs**: Chỉ thay đổi tài liệu
- **style**: Thay đổi không ảnh hưởng đến code (format, thiếu dấu chấm phẩy,...)
- **refactor**: Cải tiến code mà không thêm tính năng hay sửa lỗi
- **perf**: Cải thiện hiệu suất
- **test**: Thêm hoặc sửa test
- **chore**: Thay đổi trong quá trình build, cấu hình,...

### Ví dụ
```
feat(chat): implement hero animations for avatars

- Add HeroAvatar widget
- Integrate with chat list and detail views
- Optimize animation performance

CHAT-123
```

## Code Review

### Người tạo PR cần:
- Tự review code trước khi tạo PR
- Viết mô tả rõ ràng về những thay đổi
- Cung cấp hướng dẫn kiểm thử nếu cần
- Phản hồi các comment nhanh chóng

### Người review cần:
- Tập trung vào logic, tính bảo mật, hiệu suất và khả năng bảo trì
- Cung cấp phản hồi mang tính xây dựng
- Ưu tiên các vấn đề quan trọng
- Phân biệt rõ giữa gợi ý và yêu cầu sửa đổi

## Hướng dẫn rebase

Khi nhánh develop có thay đổi mới, bạn nên rebase nhánh feature của mình:

```bash
# Cập nhật nhánh develop
git checkout develop
git pull origin develop

# Quay lại nhánh feature và rebase
git checkout feature/CHAT-123-implement-hero-animations
git rebase develop

# Giải quyết conflict nếu có
# Sau khi giải quyết xong
git rebase --continue

# Force push sau khi rebase thành công
git push origin feature/CHAT-123-implement-hero-animations --force-with-lease
```

> **Lưu ý**: Chỉ force push khi bạn là người duy nhất làm việc trên nhánh đó.

## Quản lý version

Dự án sử dụng [Semantic Versioning](https://semver.org/) với format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Thay đổi không tương thích ngược
- **MINOR**: Thêm tính năng mới nhưng vẫn tương thích ngược
- **PATCH**: Sửa lỗi, vẫn tương thích ngược

Mỗi phiên bản được tag trên Git:

```bash
# Đánh tag cho phiên bản
git tag -a v1.2.0 -m "Version 1.2.0"

# Push tag lên remote
git push origin v1.2.0
```

## CI/CD Integration

### Pre-commit hooks

Dự án sử dụng pre-commit hooks để kiểm tra lỗi trước khi commit:

- Kiểm tra lỗi linting
- Định dạng code tự động (dart format)
- Chạy unit tests quan trọng

Cài đặt hooks:

```bash
flutter pub run pre_commit:install
```

### CI Pipeline

Mỗi PR sẽ trigger CI pipeline để:

1. Kiểm tra lỗi linting và formatting
2. Chạy unit tests và integration tests
3. Build ứng dụng trên các nền tảng được hỗ trợ

### CD Pipeline

Khi code được merge vào nhánh `main`:

1. Build phiên bản release của ứng dụng
2. Đẩy lên các kênh phân phối (TestFlight, Firebase App Distribution, Google Play Internal Testing)
3. Thông báo cho team về phiên bản mới

## Xử lý tình huống khẩn cấp

### Hotfix quy trình

1. Tạo nhánh `hotfix` từ `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/CHAT-789-crash-on-attachment-upload
   ```

2. Sửa lỗi và commit:
   ```bash
   git commit -m "fix(attachment): resolve crash when uploading large files"
   ```

3. Tạo PR để merge vào `main` và `develop`
4. Sau khi merge, tạo tag phiên bản mới (patch version)

### Rollback

Trong trường hợp cần rollback gấp:

```bash
# Xác định commit/tag cần rollback về
git checkout main
git reset --hard v1.1.0
git push origin main --force

# Hoặc revert commit cụ thể
git revert <commit-hash>
git push origin main
```

## Giải quyết conflict

### Chiến lược chung
1. Luôn pull code mới nhất từ nhánh gốc trước khi bắt đầu làm việc
2. Rebase thường xuyên để giảm thiểu conflict
3. Chia nhỏ PR để giảm khả năng xảy ra conflict lớn

### Khi gặp conflict
1. Hiểu rõ cả hai phiên bản code
2. Trao đổi với tác giả của phần code khác nếu cần
3. Ưu tiên giữ logic và cấu trúc rõ ràng, dễ hiểu

## Bảo vệ dữ liệu nhạy cảm

- **KHÔNG** commit các tệp chứa thông tin nhạy cảm như khóa API, mật khẩu, certificate
- Sử dụng `.env` cho các biến môi trường và đảm bảo tệp này được liệt kê trong `.gitignore`
- Sử dụng Flutter Flavor và Firebase Configuration riêng cho từng môi trường

## Quy tắc cho tệp .gitignore

Đảm bảo `.gitignore` bao gồm:

```
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
ios/Pods/
android/.gradle/

# IDE
.idea/
.vscode/
*.iml

# Keys và certificates
*.jks
*.keystore
*.p8
*.p12
*.key
*.mobileprovision
key.properties

# Environment và cấu hình
.env
.env.*
*.env.dart
lib/firebase_options_dev.dart
lib/firebase_options_prod.dart

# OS
.DS_Store
Thumbs.db

# Logs và cache
*.log
.fvm/
```

## Công cụ khuyến nghị

- **Git GUI**: SourceTree, GitKraken, hoặc GitHub Desktop
- **IDE Extension**: Git Lens cho VSCode hoặc Git Integration cho Android Studio
- **Diff Tool**: Meld hoặc Beyond Compare
- **Merge Tool**: KDiff3 hoặc P4Merge

## Liên kết hữu ích

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Learn Git Branching](https://learngitbranching.js.org/)
- [Oh Shit, Git!?!](https://ohshitgit.com/) - Hướng dẫn khắc phục lỗi Git thông dụng 