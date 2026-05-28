# RZ_SH

Linux 服务器运维脚本，通过交互式菜单完成 Docker 部署、反向代理、备份迁移、安全加固和系统维护。所有 Docker 数据、备份、配置均以**当前数据目录**为根（一键安装时即 `cd` 后的目录；脚本启动后会自动 `cd` 到该目录）。

## 一键安装

先 `cd` 到要存放数据和脚本的目录，再执行（脚本会落盘为当前目录下的 `r.sh`）：

```bash
cd /你的目录
bash <(curl -fsSL https://raw.githubusercontent.com/3bDjrvHs50kiZIJb5/RZ_SH/main/r.sh)
```

本地运行：`bash /path/to/RZ_SH/r.sh`（也可 `export R_SH_HOME=/path` 指定数据目录）

## 菜单树

```text
主菜单
├─ 1. Docker 基础管理
│  ├─ 1. 查看容器列表
│  ├─ 2. 启动容器
│  ├─ 3. 停止容器
│  ├─ 4. 重启容器
│  ├─ 5. 删除容器
│  ├─ 6. CLIProxyAPI（Docker Compose）
│  ├─ 7. V2RayA代理管理面板（Docker Compose）
│  ├─ 8. SQL Server数据库服务（Docker Compose）
│  ├─ 9. Nginx静态应用站（Docker Compose）
│  ├─ 10. UptimeNode监控面板（Docker Compose）
│  └─ 11. SendEmail邮件服务（Docker Compose）
├─ 2. NPM站点反代管理
│  ├─ 1. 查看 NPM 后端管理地址
│  └─ 2. 安装 NPM
├─ 3. 数据迁移
│  ├─ 1. 备份 Docker 项目目录
│  ├─ 2. 从备份恢复项目
│  └─ 3. 删除项目目录
├─ 4. 网站防护 / 安全
│  ├─ 1. 防火墙端口管理
│  │  ├─ 1. 查看防火墙规则
│  │  ├─ 2. 放行端口
│  │  └─ 3. 关闭端口
│  ├─ 2. IP 黑白名单
│  │  ├─ 1. 查看 IP 规则
│  │  ├─ 2. 放行 IP
│  │  └─ 3. 禁止 IP
│  ├─ 3. WAF / Cloudflare
│  │  ├─ 1. 启用 WAF 基础防护
│  │  ├─ 2. 启用 Cloudflare 模式
│  │  ├─ 3. 关闭当前安全配置
│  │  └─ 4. 查看安全配置文件
│  └─ 4. 拦截记录 / 日志监控
│     ├─ 1. 监控 Nginx 访问日志
│     ├─ 2. 监控 Nginx 错误日志
│     ├─ 3. 监控 Nginx 服务日志
│     ├─ 4. 监控 Docker 服务日志
│     └─ 5. 监控自定义日志文件
└─ 5. 服务器基础维护
	├─ 1. 系统更新
	├─ 2. Crontab 管理
	│  ├─ 1. 查看当前用户定时任务
	│  ├─ 2. 编辑当前用户定时任务
	│  └─ 3. 清空当前用户定时任务
	├─ 3. Swap 虚拟内存调整
	├─ 4. 时区切换
	├─ 5. SSH 端口更改
	├─ 6. 快捷键注册 / 删除（r命令）
	│  ├─ 1. 注册 r / R 命令
	│  ├─ 2. 删除 r / R 命令
	│  └─ 3. 查看当前状态
	├─ 7. DNS 优化
	│  ├─ 1. 自动识别并优化
	│  ├─ 2. 使用国内 DNS
	│  ├─ 3. 使用国外 DNS
	│  ├─ 4. 手动编辑 DNS
	│  └─ 5. 查看当前 DNS
	├─ 8. 时区 / 语言切换
	│  ├─ 1. 查看当前时区
	│  ├─ 2. 切换系统时区
	│  ├─ 3. 切换系统语言
	│  └─ 4. 查看当前语言环境
	├─ 9. Nginx Proxy Manager
	│  ├─ 1. 安装 NPM
	│  ├─ 2. 启动 NPM
	│  ├─ 3. 停止 NPM
	│  ├─ 4. 查看面板地址
	│  └─ 5. 查看安装参数
	├─ 10. CodeX CLI(API)
	│  ├─ 1. 查看当前配置
	│  ├─ 2. 安装 / 升级 CodeX CLI
	│  ├─ 3. 配置 API 模式
	│  └─ 4. 启动 CodeX CLI
	└─ 11. V2Ray-Agent安装脚本
		├─ 1. 下载并执行 V2Ray-Agent 安装脚本
		├─ 2. 卸载 V2Ray-Agent
		└─ 3. 查看安装脚本地址
```
