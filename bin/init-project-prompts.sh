#!/bin/bash

# AI Instructions Project Prompt Initializer
# 为项目初始化 AI 提示词结构，支持 GitHub Copilot CLI 和 Gemini CLI

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
DRY_RUN=false
UPDATE_MODE=false
TOOL=""
PROJECT_DIR=$(pwd)
AI_INSTRUCTIONS_DEFAULT="$HOME/ai-instructions"

# 打印帮助信息
print_help() {
    cat << EOF
用法: $0 [OPTIONS]

为项目初始化 AI 提示词结构，支持 GitHub Copilot CLI 和 Gemini CLI。

选项:
    --tool <copilot|gemini|all> 指定 AI 工具类型（可选，默认：all）
                                copilot - 仅生成 GitHub Copilot CLI 配置
                                gemini  - 仅生成 Gemini CLI 配置
                                all     - 生成所有支持的工具配置
    --dry-run                   仅显示将要执行的操作，不实际创建文件
    --update                    更新模式，检查并更新现有配置
    --help                      显示此帮助信息

示例:
    # 生成所有工具的配置（默认）
    $0

    # 仅为 GitHub Copilot CLI 初始化项目
    $0 --tool copilot

    # 仅为 Gemini CLI 初始化项目
    $0 --tool gemini

    # 预览操作（不实际执行）
    $0 --dry-run

环境变量:
    AI_INSTRUCTIONS_ROOT        ai-instructions 仓库的路径
                                默认: $HOME/ai-instructions

EOF
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --update)
            UPDATE_MODE=true
            shift
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            print_help
            exit 1
            ;;
    esac
done

# 验证必需参数
if [[ -z "$TOOL" ]]; then
    TOOL="all"
    log_info "未指定工具类型，默认生成所有工具的配置"
fi

if [[ "$TOOL" != "copilot" && "$TOOL" != "gemini" && "$TOOL" != "all" ]]; then
    log_error "不支持的工具类型: $TOOL (仅支持 copilot、gemini 或 all)"
    exit 1
fi

# 检查并设置 AI_INSTRUCTIONS_ROOT
setup_ai_instructions_root() {
    if [[ -z "$AI_INSTRUCTIONS_ROOT" ]]; then
        if [[ -d "$AI_INSTRUCTIONS_DEFAULT" ]]; then
            export AI_INSTRUCTIONS_ROOT="$AI_INSTRUCTIONS_DEFAULT"
            log_info "使用默认路径: AI_INSTRUCTIONS_ROOT=$AI_INSTRUCTIONS_ROOT"
        else
            log_error "未找到 ai-instructions 目录"
            log_error "请设置 AI_INSTRUCTIONS_ROOT 环境变量或将 ai-instructions 克隆到 $AI_INSTRUCTIONS_DEFAULT"
            exit 1
        fi
    else
        log_info "使用环境变量: AI_INSTRUCTIONS_ROOT=$AI_INSTRUCTIONS_ROOT"
    fi

    if [[ ! -d "$AI_INSTRUCTIONS_ROOT" ]]; then
        log_error "AI_INSTRUCTIONS_ROOT 指向的目录不存在: $AI_INSTRUCTIONS_ROOT"
        exit 1
    fi
}

# 创建或检查符号链接
setup_symlink() {
    local link_path="$HOME/.config/ai-prompts"
    
    if [[ -L "$link_path" ]]; then
        local current_target=$(readlink "$link_path")
        if [[ "$current_target" == "$AI_INSTRUCTIONS_ROOT" ]]; then
            log_info "符号链接已存在且正确: $link_path -> $AI_INSTRUCTIONS_ROOT"
            return
        else
            log_warn "符号链接指向不同的目录: $link_path -> $current_target"
            if [[ "$DRY_RUN" == false ]]; then
                ln -sfn "$AI_INSTRUCTIONS_ROOT" "$link_path"
                log_success "已更新符号链接: $link_path -> $AI_INSTRUCTIONS_ROOT"
            else
                log_info "[DRY RUN] 将更新符号链接: $link_path -> $AI_INSTRUCTIONS_ROOT"
            fi
        fi
    elif [[ -e "$link_path" ]]; then
        log_error "$link_path 已存在但不是符号链接"
        exit 1
    else
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$HOME/.config"
            ln -sfn "$AI_INSTRUCTIONS_ROOT" "$link_path"
            log_success "已创建符号链接: $link_path -> $AI_INSTRUCTIONS_ROOT"
        else
            log_info "[DRY RUN] 将创建符号链接: $link_path -> $AI_INSTRUCTIONS_ROOT"
        fi
    fi
}

# 创建 .ai/prompts 目录
create_prompts_dir() {
    local prompts_dir="$PROJECT_DIR/.ai/prompts"
    
    if [[ -d "$prompts_dir" ]]; then
        log_info "目录已存在: $prompts_dir"
    else
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$prompts_dir"
            log_success "已创建目录: $prompts_dir"
        else
            log_info "[DRY RUN] 将创建目录: $prompts_dir"
        fi
    fi
}

# 在 .ai/prompts 目录下创建 shared_memory.md 的符号链接
create_memory_symlink() {
    local link_dir="$PROJECT_DIR/.ai/prompts"
    local link_path="$link_dir/shared_memory.md"
    local target_path="$AI_INSTRUCTIONS_ROOT/common/shared_memory.md"

    if [[ ! -e "$target_path" ]]; then
        log_warn "未找到共享记忆文件: $target_path"
        return
    fi

    if [[ ! -d "$link_dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            log_error "目标目录不存在，无法创建符号链接: $link_dir"
            return 1
        else
            log_info "[DRY RUN] 目标目录不存在，符号链接将在实际运行时创建: $link_dir"
            return
        fi
    fi

    if [[ -L "$link_path" ]]; then
        local current_target
        current_target=$(readlink "$link_path")
        if [[ "$current_target" == "$target_path" ]]; then
            log_info "共享记忆符号链接已存在: $link_path -> $target_path"
            return
        else
            if [[ "$DRY_RUN" == false ]]; then
                ln -sfn "$target_path" "$link_path"
                log_success "已更新共享记忆符号链接: $link_path -> $target_path"
            else
                log_info "[DRY RUN] 将更新共享记忆符号链接: $link_path -> $target_path"
            fi
            return
        fi
    elif [[ -e "$link_path" ]]; then
        log_warn "存在同名文件且不是符号链接，跳过: $link_path"
        return
    fi

    if [[ "$DRY_RUN" == false ]]; then
        ln -s "$target_path" "$link_path"
        log_success "已创建共享记忆符号链接: $link_path -> $target_path"
    else
        log_info "[DRY RUN] 将创建共享记忆符号链接: $link_path -> $target_path"
    fi
}

# 递归展开 include 指令
# 参数: $1 = 文件路径
expand_includes() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    while IFS= read -r line; do
        # 检查是否是 include 指令
        if [[ "$line" =~ \{\{include:([^}]+)\}\} ]]; then
            local include_path="${BASH_REMATCH[1]}"
            
            # 扩展路径中的 ~
            include_path="${include_path/#\~/$HOME}"
            
            # 如果是相对路径，相对于当前文件所在目录
            if [[ "$include_path" == ./* ]]; then
                local dir_path=$(dirname "$file_path")
                include_path="$dir_path/${include_path#./}"
            fi
            
            # 递归展开被包含的文件
            if [[ -f "$include_path" ]]; then
                expand_includes "$include_path"
            else
                echo "<!-- 警告: 无法找到文件 $include_path -->"
            fi
        else
            # 直接输出非 include 行
            echo "$line"
        fi
    done < "$file_path"
}

# 生成 context.md 模板
create_context_template() {
    local context_file="$PROJECT_DIR/.ai/prompts/context.md"
    
    if [[ -f "$context_file" ]]; then
        if [[ "$UPDATE_MODE" == false ]]; then
            log_warn "文件已存在，跳过: $context_file"
            return
        else
            log_info "更新模式：将备份现有文件"
            if [[ "$DRY_RUN" == false ]]; then
                cp "$context_file" "$context_file.bak.$(date +%Y%m%d_%H%M%S)"
            fi
        fi
    fi

    local project_name=$(basename "$PROJECT_DIR")
    
    local content=$(cat << 'EOF'
# Project Context 项目上下文

## Project Information 项目信息

**项目名称**: <!-- 填写项目名称 -->

**项目描述**: <!-- 简要描述项目的目的和功能 -->

**仓库地址**: <!-- 如果有，填写 Git 仓库 URL -->

## Technology Stack 技术栈

**主要语言**: <!-- 例如：Python, JavaScript, TypeScript, Go 等 -->

**框架/库**: 
<!-- 列出主要使用的框架和库，例如：
- FastAPI
- React
- Django
等
-->

**开发工具**:
<!-- 列出开发过程中使用的工具，例如：
- Docker
- pytest
- ESLint
等
-->

## Project Structure 项目结构

<!-- 简要说明项目的目录结构和关键文件的作用 -->

```
project/
├── src/          # 源代码目录
├── tests/        # 测试目录
├── docs/         # 文档目录
└── ...
```

## Development Guidelines 开发指南

### Coding Standards 编码规范

<!-- 项目特定的编码规范，例如：
- 使用 4 空格缩进
- 函数名使用 snake_case
- 类名使用 PascalCase
等
-->

### Testing Requirements 测试要求

<!-- 测试相关的要求，例如：
- 所有新功能必须包含单元测试
- 测试覆盖率不低于 80%
- 使用 pytest 进行测试
等
-->

### API/Integration Notes API/集成说明

<!-- 如果项目涉及外部 API 或服务集成，在此说明：
- API 文档地址
- 认证方式
- 关键的接口说明
等
-->

## Special Constraints 特殊约束

<!-- 项目特有的约束或注意事项，例如：
- 必须兼容 Python 3.8+
- 不允许使用某些库
- 性能要求
- 安全要求
等
-->

## Current Focus 当前重点

<!-- 当前正在进行的工作或需要优先关注的方面 -->

---

**Note**: 请根据实际项目情况填写上述内容。这些信息将帮助 AI 更好地理解项目并提供更准确的帮助。
EOF
)

    if [[ "$DRY_RUN" == false ]]; then
        echo "$content" > "$context_file"
        log_success "已创建 context.md 模板: $context_file"
    else
        log_info "[DRY RUN] 将创建 context.md 模板: $context_file"
    fi
}

# 为 GitHub Copilot CLI 创建 chatmode 文件
create_copilot_chatmode() {
    local project_name=$(basename "$PROJECT_DIR")
    local chatmode_dir="$PROJECT_DIR/.github/chatmodes"
    local chatmode_file="$chatmode_dir/beastmode.chatmode.md"
    
    # 创建 .github/chatmodes 目录
    if [[ ! -d "$chatmode_dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$chatmode_dir"
            log_success "已创建目录: $chatmode_dir"
        else
            log_info "[DRY RUN] 将创建目录: $chatmode_dir"
        fi
    fi
    
    if [[ -f "$chatmode_file" ]]; then
        if [[ "$UPDATE_MODE" == false ]]; then
            log_info "文件已存在，将备份后覆盖: $chatmode_file"
            if [[ "$DRY_RUN" == false ]]; then
                cp "$chatmode_file" "$chatmode_file.bak.$(date +%Y%m%d_%H%M%S)"
                log_success "已备份到: $chatmode_file.bak.$(date +%Y%m%d_%H%M%S)"
            fi
        else
            log_info "更新模式：将备份现有文件"
            if [[ "$DRY_RUN" == false ]]; then
                cp "$chatmode_file" "$chatmode_file.bak.$(date +%Y%m%d_%H%M%S)"
            fi
        fi
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # 创建文件并写入 front matter
        cat > "$chatmode_file" << EOF
---
description: ${project_name} Development Mode (Beast Mode)
---

EOF
        
        # 复制并展开外部文件内容（chatmode-beastmode-core.md）
        local core_file="$HOME/.config/ai-prompts/common/chatmode-beastmode-core.md"
        if [[ -f "$core_file" ]]; then
            echo "# ==================== Beast Mode Core ====================" >> "$chatmode_file"
            expand_includes "$core_file" >> "$chatmode_file"
            echo "" >> "$chatmode_file"
        else
            log_error "未找到核心文件: $core_file"
            return 1
        fi
        
        # 复制并展开外部文件内容（copilot.chatmode-addon.md）
        local addon_file="$HOME/.config/ai-prompts/specific/copilot.chatmode-addon.md"
        if [[ -f "$addon_file" ]]; then
            echo "# ==================== Copilot Specific ====================" >> "$chatmode_file"
            expand_includes "$addon_file" >> "$chatmode_file"
            echo "" >> "$chatmode_file"
        else
            log_error "未找到附加文件: $addon_file"
            return 1
        fi
        
        # 要求 AI 加载项目内的 context.md 文件
        local content=$(cat << 'EOF'
# ==================== Auto Context Loading ====================
## MANDATORY FIRST ACTION
Before responding to any user request, you MUST:

1. **Auto-Load Project Context**: Use the read_file tool to load `.ai/prompts/context.md` from the current workspace root
2. **Confirm Context**: Briefly acknowledge that project context has been loaded
3. **Apply Knowledge**: Use this context information to inform all subsequent work and decisions

This ensures you always have the latest project-specific information, requirements, and architectural decisions available.
EOF
)
        echo "$content" >> "$chatmode_file"
        
        log_success "已创建 chatmode 文件: $chatmode_file"
        log_info "使用方式: gh copilot -m beastmode"
    else
        log_info "[DRY RUN] 将创建 chatmode 文件: $chatmode_file"
        log_info "[DRY RUN] 将直接复制以下文件的内容:"
        log_info "  - ~/.config/ai-prompts/common/chatmode-beastmode-core.md"
        log_info "  - ~/.config/ai-prompts/specific/copilot.chatmode-addon.md"
        log_info "[DRY RUN] 将使用 include 引用:"
        log_info "  - ./.ai/prompts/context.md"
    fi
}

# 为 Gemini CLI 创建 system.md 文件
create_gemini_system() {
    local gemini_dir="$PROJECT_DIR/.gemini"
    local system_file="$gemini_dir/system.md"
    
    # 创建 .gemini 目录
    if [[ ! -d "$gemini_dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$gemini_dir"
            log_success "已创建目录: $gemini_dir"
        else
            log_info "[DRY RUN] 将创建目录: $gemini_dir"
        fi
    fi
    
    if [[ -f "$system_file" ]]; then
        if [[ "$UPDATE_MODE" == false ]]; then
            log_info "文件已存在，将备份后覆盖: $system_file"
            if [[ "$DRY_RUN" == false ]]; then
                cp "$system_file" "$system_file.bak.$(date +%Y%m%d_%H%M%S)"
                log_success "已备份到: $system_file.bak.$(date +%Y%m%d_%H%M%S)"
            fi
        else
            log_info "更新模式：将备份现有文件"
            if [[ "$DRY_RUN" == false ]]; then
                cp "$system_file" "$system_file.bak.$(date +%Y%m%d_%H%M%S)"
            fi
        fi
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # 创建文件
        : > "$system_file"
        
        # 复制并展开外部文件内容（chatmode-beastmode-core.md）
        local core_file="$HOME/.config/ai-prompts/common/chatmode-beastmode-core.md"
        if [[ -f "$core_file" ]]; then
            echo "# ==================== Beast Mode Core ====================" >> "$system_file"
            expand_includes "$core_file" >> "$system_file"
            echo "" >> "$system_file"
        else
            log_error "未找到核心文件: $core_file"
            return 1
        fi
        
        # 复制并展开外部文件内容（gemini.system-addon.md）
        local addon_file="$HOME/.config/ai-prompts/specific/gemini.system-addon.md"
        if [[ -f "$addon_file" ]]; then
            echo "# ==================== Gemini Specific ====================" >> "$system_file"
            expand_includes "$addon_file" >> "$system_file"
            echo "" >> "$system_file"
        else
            log_error "未找到附加文件: $addon_file"
            return 1
        fi
        
        # 要求 AI 加载项目内的 context.md 文件
        local content=$(cat << 'EOF'
# ==================== Auto Context Loading ====================
## MANDATORY FIRST ACTION
Before responding to any user request, you MUST:

1. **Auto-Load Project Context**: Use the read_file tool to load `.ai/prompts/context.md` from the current workspace root
2. **Confirm Context**: Briefly acknowledge that project context has been loaded
3. **Apply Knowledge**: Use this context information to inform all subsequent work and decisions

This ensures you always have the latest project-specific information, requirements, and architectural decisions available.
EOF
)
        echo "$content" >> "$system_file"
        
        log_success "已创建 system.md 文件: $system_file"
        log_info "使用方式: 设置环境变量 GEMINI_SYSTEM_MD=true 后运行 gemini"
    else
        log_info "[DRY RUN] 将创建 system.md 文件: $system_file"
        log_info "[DRY RUN] 将直接复制以下文件的内容:"
        log_info "  - ~/.config/ai-prompts/common/chatmode-beastmode-core.md"
        log_info "  - ~/.config/ai-prompts/specific/gemini.system-addon.md"
        log_info "[DRY RUN] 将使用 include 引用:"
        log_info "  - ./.ai/prompts/context.md"
    fi
}

# 主流程
main() {
    log_info "开始为项目初始化 AI 提示词结构"
    log_info "项目目录: $PROJECT_DIR"
    log_info "AI 工具: $TOOL"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY RUN 模式：不会实际创建或修改文件"
    fi
    
    echo ""
    
    # 1. 设置 AI_INSTRUCTIONS_ROOT
    setup_ai_instructions_root
    
    # 2. 创建符号链接
    setup_symlink
    
    # 3. 创建 .ai/prompts 目录
    create_prompts_dir

    # 4. 创建 context.md 模板
    create_context_template

    # 5. 创建共享记忆符号链接
    create_memory_symlink

    # 6. 根据工具类型创建对应的入口文件
    if [[ "$TOOL" == "copilot" ]]; then
        create_copilot_chatmode
    elif [[ "$TOOL" == "gemini" ]]; then
        create_gemini_system
    elif [[ "$TOOL" == "all" ]]; then
        log_info "生成所有工具的配置..."
        create_copilot_chatmode
        create_gemini_system
    fi
    
    echo ""
    log_success "初始化完成！"
    
    if [[ "$DRY_RUN" == false ]]; then
        echo ""
        log_info "下一步："
        log_info "1. 编辑 $PROJECT_DIR/.ai/prompts/context.md，填写项目相关信息"
        if [[ "$TOOL" == "copilot" ]]; then
            log_info "2. 使用: gh copilot -m beastmode"
        elif [[ "$TOOL" == "gemini" ]]; then
            log_info "2. 设置环境变量: export GEMINI_SYSTEM_MD=true"
            log_info "3. 运行: gemini"
        elif [[ "$TOOL" == "all" ]]; then
            log_info ""
            log_info "GitHub Copilot CLI 使用方式："
            log_info "  gh copilot -m beastmode"
            log_info ""
            log_info "Gemini CLI 使用方式："
            log_info "  export GEMINI_SYSTEM_MD=true"
            log_info "  gemini"
        fi
    fi
}

# 执行主流程
main
