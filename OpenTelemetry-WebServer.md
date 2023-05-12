# Nginx 添加 OpenTelemetry 支持

## 使用 otel-webserver-module 模块

这种方式是 OpenTelemetry 官方博客推荐的方法。
参考官方文档: https://opentelemetry.io/blog/2022/instrument-nginx/

1. https://github.com/open-telemetry/opentelemetry-cpp-contrib 官方只有 **x64** 的版本， 所以不支持 arm64 镜像。
2. 官方文档中， Dockerfile 案例版本有点老， 已对版本和路径做对应修改。
3. 官方文档中， docker-compose 中使用的容器镜像都是 latest， 可能由于本地所配置的加速镜像仓库的缓存问题， 造成不能版本与配置不匹配的问题， 已修改为当前最新的固定版本。

4. 添加 mod_opentelemetry.so 之后， 会有输出很多 error 级别的日志。

**注意**：

1. 这种模式可以开启 **多层次** 的追踪。
2. 但是 **没有发现** 如何将 **Header traceparent** 传递给后段的方法。 **也没有** 发现可以使用的 **变量**， 在日志中打印 trace_id 和 span_id。


## 其他配置文档

1. OpenTelemetry Exporter, OtlpExpoerter 配置: https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/otlpexporter/README.md
2. OpenTelemetry-Cpp, Otel-WebServer-Module 配置: https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/otel-webserver-module#configuration-1

## 参考文档

1. Integrating OpenTelemetry into the Modern Apps Reference Architecture – A Progress Report: https://www.nginx.com/blog/integrating-opentelemetry-modern-apps-reference-architecture-progress-report/
2. NGINX Tutorial: How to Use OpenTelemetry Tracing to Understand Your Microservices
: https://www.nginx.com/blog/nginx-tutorial-opentelemetry-tracing-understand-microservices/
