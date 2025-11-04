# ai-instructions

为 GitHub Copilot CLI、Gemini CLI 等 AI 助手提供统一的提示词模板与辅助脚本，帮助快速在项目中搭建一致的工作流。

## 目录结构
- `common/`：通用模块（persona、workflow、coding_style、shared_memory 等），各工具都会引入。
- `specific/`：工具专属的补充说明，如 Copilot/Gemini 的系统提示。
- `chatmodes/`：预设聊天模式配置（如 Copilot CLI 的 Beast Mode）。
- `bin/`：实用脚本，核心是 `init-project-prompts.sh`，用于初始化项目配置。

## 快速开始
1. 克隆本仓库，并确保它位于 `~/ai-instructions`（或设置环境变量 `AI_INSTRUCTIONS_ROOT` 指向该路径）。
2. 进入目标项目目录，执行：
   ```bash
   /path/to/ai-instructions/bin/init-project-prompts.sh --tool all
   ```
   脚本会创建 `.ai/prompts/context.md`、生成 `.gemini/system.md`，并建立共享记忆的软链接。
3. 打开`.ai/prompts/context.md`，填写项目上下文信息。

### 共享记忆文件
初始化后，每个项目都会在 `./.ai/prompts/shared_memory.md` 暴露共享记忆（软链接指向 `common/shared_memory.md`）。请仅记录长期、跨任务有价值的偏好或事实，避免写入临时任务笔记。

## 更新已有项目
使用 `--update` 可以在不覆盖自定义内容的前提下刷新模板，例如：
```bash
bin/init-project-prompts.sh --update --tool gemini
```
