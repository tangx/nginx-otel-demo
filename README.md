# Nginx 添加 OpenTemeletry 支持

参考官方文档: https://opentelemetry.io/blog/2022/instrument-nginx/

1. https://github.com/open-telemetry/opentelemetry-cpp-contrib 官方只有 **x64** 的版本， 所以不支持 arm64 镜像。
2. 官方文档中， Dockerfile 案例版本有点老， 已对版本和路径做对应修改。
3. 官方文档中， docker-compose 中使用的容器镜像都是 latest， 可能由于本地所配置的加速镜像仓库的缓存问题， 造成不能版本与配置不匹配的问题， 已修改为当前最新的固定版本。

4. 添加 mod_opentelemetry.so 之后， 会有输出很多 error 级别的日志。



## 其他配置文档

1. OpenTelemetry Exporter, OtlpExpoerter 配置: https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/otlpexporter/README.md
2. OpenTelemetry-Cpp, Otel-WebServer-Module 配置: https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/otel-webserver-module#configuration-1

## 参考文档

1. Integrating OpenTelemetry into the Modern Apps Reference Architecture – A Progress Report: https://www.nginx.com/blog/integrating-opentelemetry-modern-apps-reference-architecture-progress-report/
2. NGINX Tutorial: How to Use OpenTelemetry Tracing to Understand Your Microservices
: https://www.nginx.com/blog/nginx-tutorial-opentelemetry-tracing-understand-microservices/


## Nginx Otel Module

1. https://github.com/open-telemetry/opentelemetry-cpp-contrib/blob/main/instrumentation/nginx/README.md
2. 日文, nginx 编译安装 otel_nginx_module.so https://ymtdzzz.dev/post/nginx-with-opentelemetry/

## (主要) 第二种方法：

在 https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx 中， 提供了独立 Nginx 使用的 otel_ngx_module.so 。

1. 官方编译的的 so 文件已经过期， 无法下载。 
2. 该版本的 so 文件 **只支持** debian 和 ubuntu

**解决方法**：

1. 通过 fork 该项目到自己环境中， 开启 Action 进行编译， 释出二进制文件。
2. 在 `.github/workflows/nginx.yml` 中， 修改以下属性值确定版本。
    + 注意， 尝试修改 **固定版本号**， 但是编译失败。 https://github.com/tangx-labs/opentelemetry-cpp-contrib/actions/runs/4949198282/jobs/8850988762
    + mainline 和 stable 对应的具体 **数值** 版本在编译时决定， 参考： https://nginx.org/en/download.html

```yaml
jobs:
  nginx-build-test:
    name: nginx
    runs-on: ubuntu-20.04
    strategy:
      matrix:
        ## 修改这里
        # os: [ubuntu-20.04, ubuntu-18.04, debian-10.11, debian-11.3]
        # nginx-rel: [1.23.1]
        nginx-rel: [mainline, stable]
        os: [ubuntu-22.04, debian-11.3]
```

如果出现类似以下错误， **则为编译时版本与运行时版本不一致**

```log
2023/05/11 14:36:35 [emerg] 1#1: module "/opt/modules/otel_ngx_module.so" version 1024000 instead of 1023004 in /etc/nginx/nginx.conf:1
```

注意， 数值版本号中分隔符 `.` 将以 0 代替。  则 1024000 -> 1.24.00, 1023004 -> 1.23.04。 因此上述错误表示， so 文件对应的 nginx 版本为 1.24.00， 而运行环境为 1.23.04， 因此版本不匹配。




