# nut-docker

用于运行 [NUT (Network UPS Tools)](https://networkupstools.org/) 的轻量 Docker 镜像。

> 当前 Dockerfile 基于 **Alpine** 多阶段构建，并从 NUT 官方发布源代码（GitHub 官方 release）编译安装，默认版本可通过构建参数 `NUT_VERSION` 覆盖。

## 可用镜像

- Docker Hub：`mgle/nut:latest`
- GHCR：`ghcr.io/mgl-cloud/nut:latest`

## 使用前提（建议）

虽然容器本身可以独立运行，但**实际使用时建议挂载配置目录**，否则你无法方便地维护 UPS 驱动、用户和监控配置。

准备本地目录（示例 `./nut-conf`）并挂载到 `/etc/nut`。

> 镜像启动时会将 NUT 默认安装在 `/etc/nut` 下的配置文件和目录自动补齐到挂载目录（仅在目标不存在时复制，不覆盖你已有配置）。

常用配置仍建议按需维护：

- `nut.conf`
- `upsd.conf`
- `ups.conf`
- `upsd.users`

容器内挂载路径统一为：`/etc/nut`。

---

## 1) 运行 NUT（默认推荐：挂载配置）

### 1.1 使用 GHCR 镜像

```bash
docker run -d \
  --name nut \
  -p 3493:3493 \
  -v ./nut-conf:/etc/nut \
  --restart unless-stopped \
  ghcr.io/mgl-cloud/nut:latest
```

### 1.2 使用 Docker Hub 镜像

```bash
docker run -d \
  --name nut \
  -p 3493:3493 \
  -v ./nut-conf:/etc/nut \
  --restart unless-stopped \
  mgle/nut:latest
```

---

## 2) 直连 USB UPS（关键）

如果 UPS 是插在 Docker 主机 USB 上，并且你要让容器内 NUT 驱动直接读取 UPS，则必须映射设备。

### 2.1 最稳妥做法：映射整条 USB 总线

```bash
docker run -d \
  --name nut \
  -p 3493:3493 \
  -v ./nut-conf:/etc/nut \
  --device /dev/bus/usb:/dev/bus/usb \
  --restart unless-stopped \
  ghcr.io/mgl-cloud/nut:latest
```

### 2.2 怎么看 USB 设备是不是识别到了？

在 Docker 主机执行：

```bash
lsusb
ls -l /dev/bus/usb/*/*
```

你会看到类似 `Bus 001 Device 004`。对应的设备节点一般是：

- `/dev/bus/usb/001/004`

> 注意：`Device 004` 这种编号在重新插拔后可能变化，所以生产环境通常直接映射 `/dev/bus/usb` 整体更稳定。

### 2.3 可不可以只映射单个设备？

可以，但不推荐长期使用（编号会变）。示例：

```bash
docker run -d \
  --name nut \
  -p 3493:3493 \
  -v ./nut-conf:/etc/nut \
  --device /dev/bus/usb/001/004:/dev/bus/usb/001/004 \
  --restart unless-stopped \
  ghcr.io/mgl-cloud/nut:latest
```

---

## 3) 不映射 `/dev/bus/usb` 能不能用 UPS？

分两种情况：

- **你的 UPS 由本机 USB 直连，本容器负责驱动读取 UPS**：
  - **不能正常读取**（通常会报找不到设备/权限错误）。
  - 结论：需要 `--device /dev/bus/usb:/dev/bus/usb`（或等价方案）。
- **UPS 数据来自别的 NUT 服务器（网络模式）**：
  - 可以不映射 USB；此时容器只做网络服务/客户端。

---

## 4) Docker Compose 示例

### 4.1 NUT（USB 直连场景）

```yaml
services:
  nut:
    image: ghcr.io/mgl-cloud/nut:latest
    container_name: nut
    ports:
      - "3493:3493"
    volumes:
      - ./nut-conf:/etc/nut
    devices:
      - /dev/bus/usb:/dev/bus/usb
    restart: unless-stopped
```

### 4.2 NUT + WebGUI

```yaml
services:
  nut:
    image: ghcr.io/mgl-cloud/nut:latest
    container_name: nut
    ports:
      - "3493:3493"
    volumes:
      - ./nut-conf:/etc/nut
    devices:
      - /dev/bus/usb:/dev/bus/usb
    restart: unless-stopped

  nut-webgui:
    image: ghcr.io/superioone/nut_webgui:latest
    container_name: nut-webgui
    depends_on:
      - nut
    environment:
      - UPSD_HOST=nut
      - UPSD_PORT=3493
    ports:
      - "8080:8080"
    restart: unless-stopped
```

常用命令：

```bash
docker compose up -d
docker compose logs -f
docker compose down
```

---

## 5) 本地构建（可选）

```bash
docker build -t nut:local .

# 指定 NUT 版本（例如）
docker build --build-arg NUT_VERSION=2.8.4 -t nut:local .

docker run -d \
  --name nut-local \
  -p 3493:3493 \
  -v ./nut-conf:/etc/nut \
  --device /dev/bus/usb:/dev/bus/usb \
  --restart unless-stopped \
  nut:local
```

---

## 6) 补充说明

- 当前镜像默认命令是 `upsd -D`。
- 如果你希望容器内同时启动驱动进程（如 `upsdrvctl start`）+ `upsd`，请在你的运行命令或编排中显式定义启动流程。

## GitHub Actions 自动发布

工作流会发布到：

- Docker Hub：`DOCKERHUB_USERNAME/nut`
- GitHub Container Registry：`ghcr.io/<owner>/nut`

需要配置仓库 Secrets：

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
