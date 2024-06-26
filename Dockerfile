# CONTAINER FOR BUILDING BINARY
FROM golang:1.21-alpine AS build

RUN apk add --no-cache --update gcc g++ make

ENV CGO_CFLAGS="-O -D__BLST_PORTABLE__"
ENV CGO_CFLAGS_ALLOW="-O -D__BLST_PORTABLE__"

# INSTALL DEPENDENCIES
COPY go.mod go.sum /src/
RUN cd /src && go mod download

# BUILD BINARY
COPY . /src
RUN cd /src && make build

FROM alpine:edge
COPY --from=build /src/dist/lagrange-cli /app/lagrange-cli
CMD ["/bin/sh", "-c", "/app/lagrange-cli version"]
