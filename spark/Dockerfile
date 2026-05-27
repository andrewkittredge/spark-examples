FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal AS base

RUN dnf install -y gcc python3.11 python3.11-devel

RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install venv-pack==0.2.0

ENV VIRTUAL_ENV=/opt/venv-library-for-spark
RUN python3.11 -m venv $VIRTUAL_ENV
# Update the PATH so that 'python' and 'pip' commands use the venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY library_for_spark-0.1.0-py3-none-any.whl /tmp/
RUN python3.11 -m pip install /tmp/library_for_spark-0.1.0-py3-none-any.whl

ARG OUTPUT_FILE_NAME
RUN mkdir /output && venv-pack -o /output/${OUTPUT_FILE_NAME}

FROM scratch AS export
ARG OUTPUT_FILE_NAME
COPY --from=base /output/${OUTPUT_FILE_NAME} /