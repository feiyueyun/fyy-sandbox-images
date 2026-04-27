# 需求文档：Agent 沙箱 OCI 镜像（fyy-sandbox-images Phase 1）

## 简介

本 Spec 定义飞越云 AI 数字员工平台的 Agent 沙箱 OCI 标准容器镜像（fyy-sandbox-images），覆盖 Phase 1 全部镜像构建、发布和框架模板交付物。该仓库作为独立的公开仓库（BSD 3-Clause 开源），提供预装 fyy CLI 的 OCI 标准容器镜像，作为 Agent Runtime Sandbox（层次一沙箱）的基础运行环境。

### 定位与产品价值

fyy-sandbox-images 是飞越云两层沙箱模型中层次一（Agent Runtime Sandbox）的核心交付物。镜像设计遵循 Agent-Native First 原则——面向 Agent（机器）使用优先，人类使用为辅。用户通过 `docker pull feiyueyun/fyy-sandbox:crewai` 即可获得完整的 Agent 开发运行环境，无需手动配置 CLI、运行时依赖和框架集成。

沙箱镜像同时是飞越云生态的独立流量入口：即使用户不使用飞越云组网能力，也可以单独使用 fyy-sandbox 镜像运行 Agent。转化漏斗为：沙箱用户 → 体验 fyy CLI → 发现组网能力 → 转化为平台用户。

### 两层沙箱模型

```
层次一：Agent Runtime Sandbox（本仓库提供）
  ├── OCI 标准镜像，fyy CLI 预装
  ├── 框架模板（crewai / langgraph / deer-flow）
  └── 适配 8 种沙箱产品：E2B、Daytona、Devcontainer、Kata Containers、
      Firecracker、Docker/Podman、gVisor/runsc、Kubernetes RuntimeClass

层次二：Skill Process Sandbox（fyy CLI 内部，不在本仓库范围）
  ├── gVisor (runsc) 锁定实现
  ├── 三级渐进式隔离：process → seccomp → gVisor
  └── 运行在层次一内时自动降级为 process 级别
```

### 跨仓库依赖关系

```
fyy（公开，闭源免费分发）←── fyy-sandbox-images（预装 CLI 二进制）
fyy-sandbox-images ←── fyy-sandbox-guides（指南引用镜像）
fyy-sandbox-images ←── agent-interop-tests（可选镜像验证测试组）
```

开发顺序约束：fyy-sandbox-images 在 fyy 二进制可构建后启动（依赖 fyy 仓库 GitHub Releases 提供预编译二进制）。

### 阶段划分

- **v1.0-alpha**：基础 OCI 镜像（feiyueyun/fyy-sandbox:latest）+ Dockerfile + CI 构建流水线
- **v1.0-beta**：框架模板镜像（feiyueyun/fyy-sandbox:crewai、feiyueyun/fyy-sandbox:langgraph、feiyueyun/fyy-sandbox:deer-flow）
- **v1.0（GA）**：所有镜像 Docker Hub 发布、Beta 反馈修复、文档完善

### 设计原则

- OCI 标准兼容：所有镜像遵循 OCI Image Specification，可在任何 OCI 兼容运行时中使用
- 最小化镜像体积：基于 Debian bookworm-slim，仅安装必要运行时依赖
- 多架构支持：linux/amd64 + linux/arm64 双架构构建
- 安全优先：非 root 用户运行、Trivy 安全扫描、v1.0 增强 cosign 签名
- fyy CLI 双模式获取：开发模式从 fyy-src 构建，发布模式从 fyy 公开仓库 Releases 下载
- Agent-Native First：镜像内环境变量、目录结构、默认配置均面向 Agent 自动化使用优化
- 框架模板开箱即用：包含可运行的示例 Agent 项目、默认自动连接官方控制平面、FYY Skills 官方技能服务自动发现与安装

### Phase 1 不包含的内容

- openclaw 框架模板（推迟到 Phase 2，与框架集成指南发布节奏一致）
- 托管沙箱服务（Phase 2 官方云平台功能）
- 沙箱监控面板（Phase 2）
- 沙箱模板市场（Phase 3）
- 企业 K8s RuntimeClass 深度集成（Phase 4）

## 术语表

- **OCI_Image**: 符合 OCI Image Specification 的容器镜像，可在 Docker、Podman、containerd 等 OCI 兼容运行时中使用
- **Base_Image**: 基础镜像（feiyueyun/fyy-sandbox:latest），预装 fyy CLI 和基础运行时环境（Python 3.12 + Node.js 22 LTS），是所有框架模板镜像的基础层
- **Framework_Template_Image**: 框架模板镜像，基于 Base_Image 构建，预装特定 AI Agent 框架（CrewAI 或 LangGraph）及其依赖，包含可运行的示例 Agent 项目
- **fyy_CLI**: 飞越云数据平面 CLI 二进制，预装在所有沙箱镜像中，是 Agent 与飞越云平台交互的核心工具
- **FYY_SANDBOX**: 环境变量标识（值为 `1`），在 Dockerfile 中通过 `ENV FYY_SANDBOX=1` 设置，供 fyy CLI 检测当前运行环境是否为层次一沙箱
- **Runtime_Detection**: 运行时环境检测，fyy CLI 通过三种方法检测是否运行在层次一沙箱内：`/.dockerenv` 文件存在、`/proc/1/cgroup` 包含容器标识、`FYY_SANDBOX=1` 环境变量。检测逻辑在 fyy CLI 代码中实现（fyy-src 仓库），本仓库仅负责设置环境变量
- **Layer1_Sandbox**: 层次一 Agent Runtime Sandbox，运行整个 Agent + CLI 环境的外部沙箱，即本仓库提供的 OCI 镜像
- **Layer2_Sandbox**: 层次二 Skill Process Sandbox，CLI 内部隔离 Skill 进程的安全沙箱，使用 gVisor (runsc)。当 CLI 检测到运行在 Layer1_Sandbox 内时，Layer2_Sandbox 自动降级为 process 级别隔离
- **Multi_Arch_Build**: 多架构构建，使用 Docker Buildx 同时构建 linux/amd64 和 linux/arm64 两种架构的镜像，通过 manifest list 统一发布
- **Trivy**: Aqua Security 开源的容器镜像安全扫描工具，用于检测镜像中的已知漏洞（CVE）
- **Cosign**: Sigstore 项目的容器镜像签名工具，用于对发布到 Docker Hub 的镜像进行数字签名，验证镜像来源可信
- **Docker_Hub**: Docker 官方容器镜像仓库，飞越云镜像发布在 `feiyueyun/` 组织下
- **CI_Pipeline**: GitHub Actions 持续集成流水线，负责镜像的自动构建、安全扫描、推送和签名
- **Skill_Manifest**: 技能清单文件（skill.json），遵循 skill-manifest-spec 标准，框架模板镜像中的示例 Agent 项目包含示例 skill.json
- **FYY Skills**: 飞越云官方技能服务体系品牌名，由多个 type=service 的 public 技能组成，CLI 加入官方网络后通过 tag:system-skill 标签自动发现并以 reference 模式安装
- **Smoke_Test**: 冒烟测试，CI 流水线中对构建完成的镜像执行的基础验证（镜像可启动、fyy CLI 可执行、Python/Node.js 可用等）
- **Image_Tag_Versioning**: 镜像标签版本策略，与 fyy CLI 版本号对齐，`latest` 标签始终指向最新稳定版本

## 需求


### REQ-1: 基础 OCI 镜像 — Dockerfile 定义（Alpha 阶段）

**用户故事:** 作为 Agent 开发者，我需要一个预装 fyy CLI 和基础运行时环境的 OCI 标准容器镜像，以便在隔离的沙箱环境中快速启动 Agent 开发和运行。

#### 验收标准

1. THE Base_Image SHALL 基于 `debian:bookworm-slim` 作为基础层构建，平衡镜像体积和软件兼容性
2. THE Base_Image SHALL 预装 fyy CLI 二进制到 `/usr/local/bin/fyy`，确保容器内任何用户均可直接执行 `fyy` 命令
3. THE Base_Image SHALL 预装 Python 3.12 运行时环境，包含 `python3` 和 `pip3` 命令，用于 MCP_Skill 的 Python 运行时依赖
4. THE Base_Image SHALL 预装 Node.js 22 LTS 运行时环境，包含 `node` 和 `npm` 命令，用于 MCP_Skill 的 Node.js 运行时依赖
5. THE Dockerfile SHALL 通过 `ENV FYY_SANDBOX=1` 设置环境变量，供 fyy CLI 检测当前运行环境为层次一沙箱
6. THE Base_Image SHALL 以非 root 用户运行容器进程（通过 `USER` 指令设置默认用户），遵循容器安全最佳实践
7. THE Dockerfile SHALL 使用多阶段构建（multi-stage build），将构建依赖与运行时环境分离，最小化最终镜像体积
8. THE Base_Image SHALL 预创建 fyy CLI 所需的工作目录结构（`~/.feiyueyun/`、`~/.feiyueyun/identity/`、`~/.feiyueyun/tsnet/`），确保 CLI 首次运行时无需额外创建目录
9. THE Base_Image SHALL 安装必要的系统工具：`ca-certificates`（TLS 证书验证）、`curl`（网络调试）、`git`（技能安装依赖）
10. THE Dockerfile SHALL 包含 `HEALTHCHECK` 指令，通过 `fyy --version` 验证 CLI 二进制可执行性
11. THE Base_Image SHALL 设置 `ENTRYPOINT` 为 `/bin/bash`，允许用户和 Agent 灵活指定启动命令

### REQ-2: fyy CLI 二进制获取 — 双模式构建（Alpha 阶段）

**用户故事:** 作为 CI 系统，我需要支持两种 fyy CLI 二进制获取方式（开发模式和发布模式），以便在不同阶段灵活构建镜像。

#### 验收标准

1. THE CI_Pipeline SHALL 支持发布模式（Release Mode）：从 fyy 公开仓库的 GitHub Releases 下载指定版本的预编译 fyy 二进制
2. THE CI_Pipeline SHALL 支持开发模式（Development Mode）：从 fyy-src 私有仓库源代码编译 fyy 二进制（需要仓库访问权限）
3. THE Dockerfile SHALL 通过构建参数（`ARG FYY_VERSION`）指定 fyy CLI 版本号，发布模式下用于定位 GitHub Releases 中的对应版本
4. THE Dockerfile SHALL 通过构建参数（`ARG FYY_BINARY_URL`）支持自定义二进制下载地址，覆盖默认的 GitHub Releases URL
5. WHEN 使用发布模式构建时，THE CI_Pipeline SHALL 验证下载的 fyy 二进制的 SHA256 校验和，确保二进制完整性
6. WHEN 使用开发模式构建时，THE CI_Pipeline SHALL 从 fyy-src 仓库的指定分支或标签编译 linux/amd64 和 linux/arm64 两个架构的二进制
7. THE CI_Pipeline SHALL 默认使用发布模式，仅在显式配置 `BUILD_MODE=dev` 时切换到开发模式
8. IF fyy 二进制下载或编译失败，THEN THE CI_Pipeline SHALL 终止构建并输出明确的错误信息（包含 URL、HTTP 状态码或编译错误日志）

### REQ-3: 多架构镜像构建（Alpha 阶段）

**用户故事:** 作为 Agent 开发者，我需要沙箱镜像同时支持 x86_64 和 ARM64 架构，以便在不同硬件平台（包括 Apple Silicon Mac 和 Linux 服务器）上使用。

#### 验收标准

1. THE CI_Pipeline SHALL 使用 Docker Buildx 构建 linux/amd64 和 linux/arm64 两种架构的镜像
2. THE CI_Pipeline SHALL 将两种架构的镜像通过 OCI manifest list 统一发布到同一镜像标签下，用户执行 `docker pull` 时自动获取匹配当前架构的镜像
3. THE Base_Image SHALL 在 linux/amd64 和 linux/arm64 两种架构上均通过 Smoke_Test 验证（fyy CLI 可执行、Python 可用、Node.js 可用）
4. THE Dockerfile SHALL 使用架构无关的安装方式（如通过包管理器安装 Python 和 Node.js），避免硬编码特定架构的下载地址
5. WHEN 构建 ARM64 架构镜像时，THE CI_Pipeline SHALL 确保 fyy CLI 二进制为 ARM64 原生编译版本，不使用 QEMU 模拟执行

### REQ-4: CI 构建流水线 — GitHub Actions（Alpha 阶段）

**用户故事:** 作为开发团队，我需要自动化的 CI 构建流水线，在代码变更时自动构建、测试和发布镜像。

#### 验收标准

1. THE CI_Pipeline SHALL 提供 GitHub Actions 工作流配置文件，在以下事件时触发构建：push 到 main 分支、pull request、手动触发（workflow_dispatch）、新版本标签（`v*`）推送
2. THE CI_Pipeline SHALL 按顺序执行以下步骤：拉取代码 → 获取 fyy CLI 二进制 → 构建多架构镜像 → 执行 Smoke_Test → 安全扫描 → 推送到 Docker Hub → 镜像签名（v1.0 增强）
3. WHEN push 到 main 分支时，THE CI_Pipeline SHALL 构建并推送带 `latest` 标签的镜像到 Docker Hub
4. WHEN 新版本标签（`v*`）推送时，THE CI_Pipeline SHALL 构建并推送带版本号标签（如 `v1.0.0`）和 `latest` 标签的镜像到 Docker Hub
5. WHEN pull request 事件时，THE CI_Pipeline SHALL 仅执行构建和 Smoke_Test，不推送到 Docker Hub
6. THE CI_Pipeline SHALL 使用 GitHub Secrets 存储 Docker Hub 认证凭据（`DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN`），不在工作流文件中硬编码敏感信息
7. THE CI_Pipeline SHALL 支持手动触发（workflow_dispatch），允许指定 fyy CLI 版本号和目标镜像标签
8. IF 构建过程中任何步骤失败，THEN THE CI_Pipeline SHALL 终止后续步骤并在 GitHub Actions 界面展示失败原因

### REQ-5: 镜像安全扫描 — Trivy 集成（Alpha 阶段）

**用户故事:** 作为安全工程师，我需要在 CI 流水线中对构建的镜像执行安全扫描，确保发布的镜像不包含已知的高危漏洞。

#### 验收标准

1. THE CI_Pipeline SHALL 在镜像推送到 Docker Hub 之前执行 Trivy 安全扫描
2. THE Trivy 扫描 SHALL 检测镜像中的操作系统包漏洞和应用依赖漏洞
3. WHEN Trivy 扫描发现 CRITICAL 或 HIGH 级别漏洞时，THE CI_Pipeline SHALL 将扫描结果作为 CI artifact 上传，并在构建日志中输出漏洞摘要
4. THE CI_Pipeline SHALL 支持通过配置文件（`.trivyignore`）忽略已知的误报或已接受风险的漏洞
5. THE Trivy 扫描结果 SHALL 以 SARIF 格式输出，支持 GitHub Security 面板集成
6. WHEN 手动触发构建时，THE CI_Pipeline SHALL 支持通过参数 `TRIVY_SEVERITY` 配置扫描阈值（默认 `CRITICAL,HIGH`）

### REQ-6: 镜像签名 — Cosign 集成（v1.0 增强）

**用户故事:** 作为安全工程师，我需要对发布到 Docker Hub 的镜像进行数字签名，以便用户验证镜像来源的可信性。

#### 验收标准

1. THE CI_Pipeline SHALL 在镜像推送到 Docker Hub 之后使用 Cosign 对镜像进行数字签名
2. THE Cosign 签名 SHALL 使用 GitHub Actions OIDC 提供的 keyless 签名方式（Sigstore Fulcio + Rekor），无需管理私钥
3. THE 仓库 README SHALL 包含镜像签名验证命令示例，指导用户使用 `cosign verify` 验证镜像签名
4. WHEN 镜像签名失败时，THE CI_Pipeline SHALL 记录签名错误日志但不阻塞镜像发布（签名为增强安全措施，不影响可用性）

### REQ-7: 镜像标签版本策略（Alpha 阶段）

**用户故事:** 作为 Agent 开发者，我需要清晰的镜像标签版本策略，以便选择合适的镜像版本用于开发和生产环境。

#### 验收标准

1. THE Image_Tag_Versioning SHALL 与 fyy CLI 版本号对齐，镜像标签格式为 `feiyueyun/fyy-sandbox:<tag>`
2. THE `latest` 标签 SHALL 始终指向最新稳定版本的 Base_Image
3. WHEN 发布新版本时，THE CI_Pipeline SHALL 同时推送版本号标签（如 `v1.0.0`）和更新 `latest` 标签
4. THE 框架模板镜像 SHALL 使用框架名称作为标签（如 `crewai`、`langgraph`），同时支持带版本号的标签（如 `crewai-v1.0.0`）
5. THE CI_Pipeline SHALL 在每次构建时为镜像添加 OCI 标准标签（labels）：`org.opencontainers.image.version`、`org.opencontainers.image.source`、`org.opencontainers.image.created`、`org.opencontainers.image.description`、`org.opencontainers.image.licenses`
6. THE 仓库 README SHALL 列出所有可用的镜像标签及其用途说明

### REQ-8: 冒烟测试 — 镜像基础验证（Alpha 阶段）

**用户故事:** 作为 CI 系统，我需要在镜像构建完成后执行冒烟测试，验证镜像的基础功能正确性。

#### 验收标准

1. THE Smoke_Test SHALL 验证镜像可以成功启动容器（`docker run` 返回退出码 0）
2. THE Smoke_Test SHALL 验证 fyy CLI 二进制可执行（`fyy --version` 返回退出码 0 且输出包含版本号）
3. THE Smoke_Test SHALL 验证 Python 3.12 运行时可用（`python3 --version` 返回退出码 0 且输出包含 `3.12`）
4. THE Smoke_Test SHALL 验证 Node.js 22 LTS 运行时可用（`node --version` 返回退出码 0 且输出包含 `v22`）
5. THE Smoke_Test SHALL 验证 `pip3` 包管理器可用（`pip3 --version` 返回退出码 0）
6. THE Smoke_Test SHALL 验证 `npm` 包管理器可用（`npm --version` 返回退出码 0）
7. THE Smoke_Test SHALL 验证环境变量 `FYY_SANDBOX` 的值为 `1`
8. THE Smoke_Test SHALL 验证 `/.dockerenv` 文件存在（Docker 运行时自动创建，用于运行时环境检测）
9. THE Smoke_Test SHALL 验证容器以非 root 用户运行（`whoami` 输出不为 `root`）
10. THE Smoke_Test SHALL 验证 fyy CLI 工作目录结构存在（`~/.feiyueyun/` 目录及子目录）
11. THE Smoke_Test SHALL 验证 `ca-certificates`、`curl`、`git` 系统工具可用
12. WHEN 任何冒烟测试项失败时，THE CI_Pipeline SHALL 终止构建流程并输出失败的测试项和详细错误信息

### REQ-9: 运行时环境检测支持（Alpha 阶段）

**用户故事:** 作为 fyy CLI，我需要沙箱镜像正确设置运行时环境标识，以便检测到当前运行在层次一沙箱内时自动将层次二 Skill 沙箱降级为 process 级别。

#### 验收标准

1. THE Dockerfile SHALL 通过 `ENV FYY_SANDBOX=1` 设置环境变量，作为运行时环境检测的主要标识
2. THE Base_Image SHALL 确保 `/.dockerenv` 文件在 Docker 运行时中自动存在（由 Docker 引擎创建，Dockerfile 无需额外操作）
3. THE Base_Image SHALL 确保 `/proc/1/cgroup` 在容器运行时包含容器标识信息（由 Linux 内核和容器运行时提供，Dockerfile 无需额外操作）
4. THE 仓库文档 SHALL 说明三种运行时检测方法的优先级和适用场景：`FYY_SANDBOX=1` 环境变量（最可靠，适用于所有 OCI 运行时）、`/.dockerenv` 文件（Docker 特有）、`/proc/1/cgroup` 容器标识（Linux 内核级别）
5. THE 仓库文档 SHALL 说明当 fyy CLI 检测到运行在层次一沙箱内时的自动行为：层次二 Skill 沙箱降级为 process 级别隔离，原因是 gVisor 无法在容器内嵌套运行

### REQ-10: CrewAI 框架模板镜像（Beta 阶段）

**用户故事:** 作为使用 CrewAI 框架的 Agent 开发者，我需要一个预装 CrewAI 框架和 fyy CLI 的容器镜像，以便开箱即用地在沙箱环境中开发和运行 CrewAI Agent。

#### 验收标准

1. THE Framework_Template_Image（`feiyueyun/fyy-sandbox:crewai`）SHALL 基于 Base_Image 构建，继承所有基础运行时环境
2. THE CrewAI 模板镜像 SHALL 预装 CrewAI 框架及其 Python 依赖（通过 `pip install crewai` 安装）
3. THE CrewAI 模板镜像 SHALL 包含一个可运行的示例 Agent 项目，位于 `/home/fyy/example-agent/` 目录
4. THE 示例 Agent 项目 SHALL 包含以下文件：`main.py`（Agent 入口）、`requirements.txt`（Python 依赖声明）、`skill.json`（符合 skill-manifest-spec 标准的示例技能清单）、`README.md`（使用说明）
5. THE 示例 Agent 项目 SHALL 默认配置自动连接飞越云官方控制平面（fyy CLI 默认行为）
6. THE 示例 Agent 项目 SHALL 在连接官方控制平面后自动发现并安装 FYY Skills 官方技能服务（通过 tag:system-skill 标签自动识别，reference 模式安装），使 Agent 可通过标准技能发现机制感知飞越云平台能力
7. THE 示例 Agent 项目 SHALL 包含 CrewAI 框架与 fyy CLI 的集成示例代码，展示如何通过 fyy CLI 安装和调用技能
8. THE CrewAI 模板镜像 SHALL 通过 Smoke_Test 验证：CrewAI 框架可导入（`python3 -c "import crewai"` 返回退出码 0）、示例项目目录结构完整
9. THE CrewAI 模板镜像 SHALL 在 linux/amd64 和 linux/arm64 两种架构上均可构建和运行

### REQ-11: LangGraph 框架模板镜像（Beta 阶段）

**用户故事:** 作为使用 LangGraph 框架的 Agent 开发者，我需要一个预装 LangGraph 框架和 fyy CLI 的容器镜像，以便开箱即用地在沙箱环境中开发和运行 LangGraph Agent。

#### 验收标准

1. THE Framework_Template_Image（`feiyueyun/fyy-sandbox:langgraph`）SHALL 基于 Base_Image 构建，继承所有基础运行时环境
2. THE LangGraph 模板镜像 SHALL 预装 LangGraph 框架及其 Python 依赖（通过 `pip install langgraph` 安装）
3. THE LangGraph 模板镜像 SHALL 包含一个可运行的示例 Agent 项目，位于 `/home/fyy/example-agent/` 目录
4. THE 示例 Agent 项目 SHALL 包含以下文件：`main.py`（Agent 入口）、`requirements.txt`（Python 依赖声明）、`skill.json`（符合 skill-manifest-spec 标准的示例技能清单）、`README.md`（使用说明）
5. THE 示例 Agent 项目 SHALL 默认配置自动连接飞越云官方控制平面（fyy CLI 默认行为）
6. THE 示例 Agent 项目 SHALL 在连接官方控制平面后自动发现并安装 FYY Skills 官方技能服务（通过 tag:system-skill 标签自动识别，reference 模式安装），使 Agent 可通过标准技能发现机制感知飞越云平台能力
7. THE 示例 Agent 项目 SHALL 包含 LangGraph 框架与 fyy CLI 的集成示例代码，展示如何通过 fyy CLI 安装和调用技能
8. THE LangGraph 模板镜像 SHALL 通过 Smoke_Test 验证：LangGraph 框架可导入（`python3 -c "import langgraph"` 返回退出码 0）、示例项目目录结构完整
9. THE LangGraph 模板镜像 SHALL 在 linux/amd64 和 linux/arm64 两种架构上均可构建和运行

### REQ-12: Docker Hub 发布与组织管理（Alpha 阶段）

**用户故事:** 作为开发团队，我需要将构建的镜像发布到 Docker Hub 的 feiyueyun 组织下，以便用户通过标准的 `docker pull` 命令获取镜像。

#### 验收标准

1. THE CI_Pipeline SHALL 将所有镜像推送到 Docker Hub 的 `feiyueyun/` 组织命名空间下
2. THE Docker Hub 仓库 SHALL 配置仓库描述（Repository Description），包含镜像用途、支持的架构和可用标签列表
3. THE Docker Hub 仓库 SHALL 配置 README（Repository Overview），与 GitHub 仓库 README 保持同步
4. WHEN 推送镜像到 Docker Hub 时，THE CI_Pipeline SHALL 验证推送成功（检查 Docker Hub API 返回的 digest）
5. THE CI_Pipeline SHALL 在推送完成后输出镜像的完整 digest（`sha256:...`），用于镜像完整性验证

### REQ-13: 仓库文档与使用指南（Alpha 阶段）

**用户故事:** 作为 Agent 开发者，我需要清晰的仓库文档和使用指南，以便快速了解如何使用沙箱镜像。

#### 验收标准

1. THE 仓库 README SHALL 包含以下章节：项目简介（飞越云沙箱镜像的定位和价值）、快速开始（docker pull + docker run 示例）、可用镜像列表（标签、架构、用途）、构建说明（本地构建方法）、许可证（BSD 3-Clause）
2. THE 仓库 README SHALL 包含每个镜像标签的使用示例，至少覆盖：`latest`（基础镜像）、`crewai`（CrewAI 框架模板）、`langgraph`（LangGraph 框架模板）
3. THE 仓库 README SHALL 包含镜像签名验证说明（v1.0 增强后），指导用户使用 cosign 验证镜像来源
4. THE 仓库 SHALL 包含 `CONTRIBUTING.md` 文件，说明如何贡献新的框架模板或改进现有镜像
5. THE 仓库 SHALL 包含 `LICENSE` 文件（BSD 3-Clause），明确 Dockerfile 和构建脚本的开源许可
6. THE 仓库 README SHALL 说明 fyy CLI 二进制的许可状态：fyy CLI 为闭源免费分发，与 BSD 3-Clause 开源的 Dockerfile 和构建脚本不冲突（类似 Docker 镜像预装 curl 的模式）

### REQ-14: 沙箱兼容性设计约束（Alpha 阶段）

**用户故事:** 作为平台架构师，我需要沙箱镜像兼容多种编排环境和沙箱运行时，确保镜像可在 8 种目标沙箱产品中正常运行。

#### 验收标准

1. THE Base_Image SHALL 遵循 OCI Image Specification，确保镜像可在任何 OCI 兼容运行时中使用（Docker、Podman、containerd、CRI-O 等）
2. THE Base_Image SHALL 兼容 "有 Agent" 和 "无 Agent（仅 Device）" 两种使用场景：有 Agent 时 fyy CLI 作为 Agent 的基础设施工具使用，无 Agent 时 fyy CLI 独立运行提供或消费技能服务
3. THE Base_Image SHALL 确保 fyy CLI 在控制平面不可用时可正常启动并进入降级运行模式（已建立的连接继续工作，使用本地缓存的 Grants 和技能目录）
4. THE Base_Image SHALL 兼容 Skill_Manifest 标准（skill-manifest-spec），镜像内的 fyy CLI 使用 `pkg/manifest/` 解析库处理 skill.json
5. THE Dockerfile SHALL 避免使用 Docker 特有的功能（如 `--security-opt`），确保镜像在 Podman、gVisor、Kata Containers 等非 Docker 运行时中同样可用
6. THE Base_Image SHALL 确保文件系统权限设置允许非 root 用户在 `~/.feiyueyun/` 目录下读写数据，兼容各种运行时的用户映射策略

### REQ-15: v1.0 稳定化 — Beta 反馈修复与文档完善（v1.0 阶段）

**用户故事:** 作为开发团队，我需要在 v1.0 正式发布前修复 Beta 阶段收集的反馈问题，完善文档，确保所有镜像在 Docker Hub 上稳定可用。

#### 验收标准

1. THE 开发团队 SHALL 修复 Beta 阶段用户反馈的镜像构建、运行时兼容性和文档问题
2. THE CI_Pipeline SHALL 确保所有镜像标签（`latest`、`crewai`、`langgraph`）在 Docker Hub 上可用且通过 Smoke_Test
3. THE 仓库文档 SHALL 更新为 v1.0 正式版内容，包含完整的镜像列表、使用指南和故障排除说明
4. THE 框架模板镜像中的示例 Agent 项目 SHALL 经过端到端验证：可成功启动、连接飞越云网络、安装和运行示例技能
5. THE CI_Pipeline SHALL 在 v1.0 发布时启用 Cosign 镜像签名（REQ-6 交付）

### REQ-17: DeerFlow 框架模板镜像（Phase 1 增量）

**用户故事:** 作为使用 DeerFlow 框架的 Agent 开发者，我需要一个预装 DeerFlow 框架和 fyy CLI 的容器镜像，以便开箱即用地在沙箱环境中开发和运行 DeerFlow 多 Agent 工作流。

#### 背景

DeerFlow（`https://github.com/bytedance/deer-flow`）是字节跳动开源的长周期 SuperAgent 编排框架，基于 LangGraph 构建，支持多 Agent 协同、沙箱执行、记忆管理、工具调用和消息网关。DeerFlow 使用 Python 3.12+ 作为后端语言，FastAPI + uvicorn 作为 API 网关，Next.js (TypeScript) 作为前端 UI。核心依赖包括 `deerflow-harness`、`langgraph`、`langchain`、`langgraph-sdk`、`fastapi` 等。

#### 验收标准

1. THE Framework_Template_Image（`feiyueyun/fyy-sandbox:deer-flow`）SHALL 基于 Base_Image 构建，继承所有基础运行时环境
2. THE DeerFlow 模板镜像 SHALL 预装 DeerFlow 框架核心 Python 依赖（`deerflow-harness`、`langgraph`、`langchain`、`langchain-core`、`langgraph-sdk`、`langgraph-cli` 等）
3. THE DeerFlow 模板镜像 SHALL 包含一个可运行的示例 Agent 项目，位于 `/home/fyy/example-agent/` 目录
4. THE 示例 Agent 项目 SHALL 包含以下文件：`main.py`（Agent 入口）、`requirements.txt`（Python 依赖声明）、`skill.json`（符合 skill-manifest-spec 标准的示例技能清单）、`README.md`（使用说明）
5. THE 示例 Agent 项目 SHALL 默认配置自动连接飞越云官方控制平面（fyy CLI 默认行为）
6. THE 示例 Agent 项目 SHALL 在连接官方控制平面后自动发现并安装 FYY Skills 官方技能服务（通过 tag:system-skill 标签自动识别，reference 模式安装），使 Agent 可通过标准技能发现机制感知飞越云平台能力
7. THE 示例 Agent 项目 SHALL 包含 DeerFlow 框架与 fyy CLI 的集成示例代码，展示如何通过 fyy CLI 安装和调用技能
8. THE DeerFlow 模板镜像 SHALL 通过 Smoke_Test 验证：DeerFlow 核心框架可导入（`python3 -c "import deerflow"` 返回退出码 0）、示例项目目录结构完整
9. THE DeerFlow 模板镜像 SHALL 在 linux/amd64 和 linux/arm64 两种架构上均可构建和运行

### REQ-16: 正确性属性 — 镜像构建不变量验证

**用户故事:** 作为平台开发者，我需要验证镜像构建过程中的关键不变量，确保每次构建产出的镜像满足一致性和正确性要求。

#### 验收标准

1. THE Smoke_Test SHALL 验证不变量：fyy CLI 版本一致性 — 镜像内 `fyy --version` 输出的版本号与构建参数 `FYY_VERSION` 指定的版本号一致
2. THE Smoke_Test SHALL 验证不变量：框架模板继承完整性 — 所有 Framework_Template_Image 中 `fyy --version`、`python3 --version`、`node --version` 的输出与 Base_Image 中的输出一致（框架模板不改变基础运行时版本）
3. THE Smoke_Test SHALL 验证不变量：环境变量持久性 — `FYY_SANDBOX=1` 环境变量在容器启动后始终存在，不受用户命令或 ENTRYPOINT 脚本影响
4. THE Smoke_Test SHALL 验证不变量：非 root 用户约束 — 容器默认进程的 UID 不为 0（非 root），且 fyy CLI 工作目录对该用户可读写
5. THE Smoke_Test SHALL 验证幂等性：使用相同的构建参数（`FYY_VERSION`、基础镜像版本）重复构建时，产出的镜像层内容一致（排除时间戳等元数据差异）
6. THE CI_Pipeline SHALL 验证多架构一致性：linux/amd64 和 linux/arm64 两种架构的镜像在 Smoke_Test 中产出相同的功能验证结果（fyy CLI 可执行、Python 可用、Node.js 可用、环境变量正确）
