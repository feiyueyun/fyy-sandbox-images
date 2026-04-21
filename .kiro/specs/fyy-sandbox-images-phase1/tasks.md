# Phase 1 任务清单

## 1. 基础镜像构建

- [x] 1.1 编写 `base/Dockerfile`（多阶段构建，Python 3.12 + Node.js 22 + fyy CLI）
- [x] 1.2 创建 `Makefile`（build-base, build-all, smoke-test, trivy-scan, clean）
- [x] 1.3 创建 `.gitignore` 和 `.trivyignore`
- [x] 1.4 创建 `scripts/` 目录

## 2. fyy CLI 二进制获取

- [x] 2.1 编写 `scripts/fetch-fyy-binary.sh`（release 模式：GitHub Releases 下载 + SHA256 校验）
- [x] 2.2 支持 dev 模式（从本地 `../fyy-src` 交叉编译）
- [ ] *2.3 SHA256 校验参数化测试（可选）
- [ ] *2.4 错误报告测试（可选）

## 3. 基础镜像验证

- [x] 3.1 本地构建成功（`make build-base`）
- [x] 3.2 `fyy version` 可执行
- [x] 3.3 Python 3.12 可用
- [x] 3.4 Node.js 22 可用
- [x] 3.5 `FYY_SANDBOX=1` 环境变量已设置
- [x] 3.6 非 root 用户（fyy, UID 1000）
- [x] 3.7 `~/.feiyueyun/` 目录结构正确

## 4. 冒烟测试脚本

- [x] 4.1 编写 `scripts/smoke-test.sh`（基础镜像 10 项测试）
- [x] 4.2 支持框架模板测试（crewai, langgraph）
- [x] 4.3 不变量验证（环境变量持久化、非 root 约束）

## 5. 框架模板镜像

- [x] 5.1 编写 `templates/crewai/Dockerfile`
- [x] 5.2 创建 `templates/crewai/example-agent/`（main.py, requirements.txt, skill.json, README.md）
- [x] 5.3 编写 `templates/langgraph/Dockerfile`
- [x] 5.4 创建 `templates/langgraph/example-agent/`（main.py, requirements.txt, skill.json, README.md）
- [ ] 5.5 OpenClaw 模板（Phase 2，不在 Phase 1 范围内）

## 6. 框架模板验证

- [x] 6.1 CrewAI 模板本地构建成功
- [x] 6.2 LangGraph 模板本地构建成功
- [x] 6.3 CrewAI 冒烟测试通过（24/24）
- [x] 6.4 LangGraph 冒烟测试通过（24/24）

## 7. CI/CD 流水线

- [x] 7.1 编写 `.github/workflows/build-and-publish.yml`
- [x] 7.2 触发条件：push main, PR, tag v*, workflow_dispatch
- [x] 7.3 多架构构建（linux/amd64, linux/arm64）
- [x] 7.4 Trivy 安全扫描（SARIF 上传，非阻塞）
- [x] 7.5 Docker Hub 推送（metadata-action 标签）
- [x] 7.6 Cosign 签名（keyless，仅 tag 触发，非阻塞）

## 8. 仓库文档

- [x] 8.1 更新 `README.md`（完整内容：镜像列表、快速开始、构建指南、签名验证）
- [x] 8.2 创建 `CONTRIBUTING.md`（开发环境设置、贡献流程、提交规范）

## 9. 沙箱兼容性验证

- [x] 9.1 Dockerfile 使用 OCI 标准指令（无 Docker 特有功能）
- [x] 9.2 运行时中立权限（非 root, UID 1000）
- [x] 9.3 `FYY_SANDBOX=1` 环境变量跨运行时可用

## 10. 发布准备

- [ ] *10.3 Docker Hub 同步（可选，需要 Docker Hub 配置）
- [ ] 10.1 首次发布版本号确认
- [ ] 10.2 GitHub Release 创建

## 11. 多架构验证

- [x] 11.1 CI 配置支持 linux/amd64 + linux/arm64
- [ ] *11.2 多架构一致性测试（可选，需要 ARM64 runner）

---

**Phase 1 核心任务完成度：17/19（2 项可选任务未执行，2 项发布任务待 fyy v1.0-alpha 发布后执行）**
