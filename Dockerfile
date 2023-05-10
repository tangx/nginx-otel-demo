# 这只是一个测试文档， 没有进行优化

FROM nginx:1.23.1 as builder
WORKDIR /opt

#####################
## 测试/备选方案: 在容器中，网络差的时候，可以先下载到本地，在进行编译
# wget -c https://github.com/open-telemetry/opentelemetry-cpp-contrib/releases/download/webserver%2Fv1.0.3/opentelemetry-webserver-sdk-x64-linux.tgz
####################
COPY opentelemetry-webserver-sdk-x64-linux.tgz .
RUN tar xf opentelemetry-webserver-sdk-x64-linux.tgz \
    && cd /opt/opentelemetry-webserver-sdk; ./install.sh \
    && rm -f opentelemetry-webserver-sdk-x64-linux.tgz


ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/opentelemetry-webserver-sdk/sdk_lib/lib
RUN echo "load_module /opt/opentelemetry-webserver-sdk/WebServerModule/Nginx/1.23.1/ngx_http_opentelemetry_module.so;\n$(cat /etc/nginx/nginx.conf)" > /etc/nginx/nginx.conf
COPY ./conf.d/nginx/opentelemetry_module.conf /etc/nginx/conf.d