FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal AS base

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y gcc python3.11 python3.11-devel

COPY library_for_spark-0.1.0-py3-none-any.whl /tmp/

ENV VIRTUAL_ENV=/opt/venv-library-for-spark
RUN python3.11 -m venv $VIRTUAL_ENV
# Update the PATH so that 'python' and 'pip' commands use the venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN --mount=type=cache,target=/root/.cache/pip \
    python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install \
    venv-pack==0.2.0 \
    /tmp/library_for_spark-0.1.0-py3-none-any.whl

ARG OUTPUT_FILE_NAME
RUN mkdir /output && venv-pack -o /output/${OUTPUT_FILE_NAME}

FROM scratch AS export
ARG OUTPUT_FILE_NAME
COPY --from=base /output/${OUTPUT_FILE_NAME} /