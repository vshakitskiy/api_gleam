FROM ghcr.io/gleam-lang/gleam:v1.9.1-erlang-alpine

COPY . /build/

RUN apk add gcc build-base \
  && cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del gcc build-base

FROM ghcr.io/gleam-lang/gleam:v1.9.1-erlang
WORKDIR /app
COPY --from=0 /app /app

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

CMD /wait-for-it.sh db:5555 --timeout=30 -- \
  /app/entrypoint.sh run migrate up && \
  /app/entrypoint.sh run dev