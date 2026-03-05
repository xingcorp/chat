Analyze the current state of the Sharitek Office Chat project.

## Steps

1. **Read Project Status**
   - Read `.kiro/PROJECT_STATUS_ANALYSIS.md` for the full gap analysis
   - Read `.kiro/steering/project-architecture.md` for architecture overview

2. **Check Current Implementation**
   - Scan `flutter_chat_app/lib/domain/usecases/` for implemented use cases
   - Scan `flutter_chat_app/lib/data/graphql/` for GraphQL operations
   - Scan `flutter_chat_app/lib/presentation/blocs/` for BLoC implementation
   - Check `flutter_chat_app/lib/core/services/` for real-time event coverage

3. **Report**
   Provide a concise status report:
   - Overall completion percentage
   - What's working vs what's broken
   - Next highest-priority tasks
   - Estimated effort for each task

4. **Suggest Next Action**
   Based on the analysis, recommend the single most impactful thing to work on next.
