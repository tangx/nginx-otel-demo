# Nginx 添加 OpenTemeletry 支持


## Nginx 模块 `otel_ngx_module.so` 

1. https://github.com/open-telemetry/opentelemetry-cpp-contrib/blob/main/instrumentation/nginx/README.md

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


### 配置管理

官方给出了详细的配置案例， 可以直接参考。

这里列出需要配置变更。

#### 1. Nginx 变量管理

```conf
# 加载 so 文件
load_module /path/to/otel_ngx_module.so;

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      # 可以全局使用 opentelemetry 的变量
                      '"$opentelemetry_trace_id" '
                      '"$opentelemetry_context_traceparent" '
                      ;
    access_log  /var/log/nginx/access.log  main;
}
```

1. 在最外层加载 otel_ngx_module.so 文件。
2. 之后 http, server, location 中使用相关 [Nginx 变量](https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx#nginx-variables)


#### 2. TraceParent 传递

如果收集跟踪信息， 需要提供相应配置。 以下是 `otel-nginx.toml` 的配置内容。

```toml
exporter = "otlp"
processor = "batch"

## 配置收集器 Collector 信息。
## 通常只需要修改这个地方就行了。
[exporters.otlp]
# Alternatively the OTEL_EXPORTER_OTLP_ENDPOINT environment variable can also be used.
### 收集器地址
host = "localhost"
port = 4317
# Optional: enable SSL, for endpoints that support it
# use_ssl = true
# Optional: set a filesystem path to a pem file to be used for SSL encryption
# (when use_ssl = true)
# ssl_cert_path = "/path/to/cert.pem"

[processors.batch]
max_queue_size = 2048
schedule_delay_millis = 5000
max_export_batch_size = 512

[service]
# Can also be set by the OTEL_SERVICE_NAME environment variable.
name = "nginx-proxy" # Opentelemetry resource name

[sampler]
name = "AlwaysOn" # Also: AlwaysOff, TraceIdRatioBased
ratio = 0.1
parent_based = false
```

**注意**： 文章中说可以通过环境变量 `OTEL_EXPORTER_OTLP_ENDPOINT="localhost:4317"` 来管理收集器地址。 经测试， 这种方法是不可用的。


对应的， 在咋 nginx 配置中， 需要做相应的修改

```conf
## 加载 so 文件
load_module /path/to/otel_ngx_module.so;

http {
  ## 指定跟踪配置文件
  opentelemetry_config /conf/otel-nginx.toml;

  server {
    listen 80;
    server_name otel_example;

    root /var/www/html;

    location = / {

      # 指定跟踪服务名称
      opentelemetry_operation_name my_example_backend;
      # 添加 header， 向后传递 traceparent
      opentelemetry_propagate;
      proxy_pass http://localhost:3500/;
    }

    location = /b3 {
      opentelemetry_operation_name my_other_backend;
      ## b3 模式
      opentelemetry_propagate b3;
      ## 添加用户自定义属性
      # Adds a custom attribute to the span
      opentelemetry_attribute "req.time" "$msec";
      proxy_pass http://localhost:3501/;
    }

    location ~ \.php$ {
      root /var/www/html/php;
      opentelemetry_operation_name php_fpm_backend;
      opentelemetry_propagate;
      fastcgi_pass localhost:9000;
      include fastcgi.conf;
    }
  }
}
```



## 参考文档

官方针对的是 debian 下的 nginx 进行的 so 文件编译。 如果需要使用 alpine 环境， 可以参考博客 [alpine nginx 安装编译 otel_ngx_module.so](https://ymtdzzz.dev/post/nginx-with-opentelemetry/)。 文章是针对 openrestry 实现的， 并且实现较早， 直接替换使用 `nginx:1.24-alpine` 是不行的。

同样的， **也不能** 直接使用 debian 下编译的 so 文件到 alpine 下使用。

```log
2023/05/12 09:02:18 [emerg] 1#1: dlopen() "/opt/modules/otel_ngx_module.so" failed (Error loading shared library libstdc++.so.6: No such file or directory (needed by /opt/modules/otel_ngx_module.so)) in /etc/nginx/nginx.conf:2
nginx: [emerg] dlopen() "/opt/modules/otel_ngx_module.so" failed (Error loading shared library libstdc++.so.6: No such file or directory (needed by /opt/modules/otel_ngx_module.so)) in /etc/nginx/nginx.conf:2
```