# Simulates a CI runner whose anonymous api.github.com quota is exhausted:
# api.github.com is blackholed while github.com and opencode.ai stay reachable.
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN printf 'resolve = api.github.com:443:127.0.0.1\n' > /root/.curlrc \
    && printf 'resolve = api.github.com:443:127.0.0.1\n' > /home/vscode/.curlrc \
    && chown vscode:vscode /home/vscode/.curlrc
