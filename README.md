# R_SH

Linux 服务器运维脚本，通过交互式菜单完成 Docker 部署、反向代理、备份迁移、安全加固和系统维护。数据目录默认建在 `r.sh` 同级。

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/3bDjrvHs50kiZIJb5/RZ_SH/main/r.sh)
```

本地运行：`bash /path/to/R_SH/r.sh`

## 主菜单

| 选项 | 说明 |
|------|------|
| **1. Docker 基础管理** | 查看/启停容器，以及 CLIProxyAPI、V2RayA、SQL Server、Nginx 静态站、UptimeNode、SendEmail 等 Compose 服务 |
| **2. NPM 站点反代管理** | 安装与访问 Nginx Proxy Manager，配置域名反代和 SSL |
| **3. 数据迁移** | 备份、恢复、删除 Docker 项目目录 |
| **4. 网站防护 / 安全** | 防火墙端口、IP 黑白名单、WAF / Cloudflare、日志监控 |
| **5. 服务器基础维护** | 系统更新、定时任务、Swap、时区/SSH/DNS、NPM、CodeX CLI、V2Ray-Agent 等 |
| **0. 退出** | 退出脚本 |
