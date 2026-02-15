# Build the inference-router binary
FROM golang:1.25 AS builder

# Copy in the go src
WORKDIR /go/src/github.com/kserve/kserve
COPY go.mod  go.mod
COPY go.sum  go.sum

RUN go mod download

COPY cmd/router/ cmd/router/
COPY pkg/    pkg/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOFLAGS=-mod=readonly go build -a -o router ./cmd/router

# Generate third-party licenses
COPY LICENSE LICENSE
RUN go install github.com/google/go-licenses@latest && \
    go-licenses check ./cmd/router ./pkg/... --disallowed_types="forbidden,unknown" && \
    go-licenses save --save_path third_party/library ./cmd/router

# Copy the inference-router into a thin image
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /go/src/github.com/kserve/kserve/third_party /third_party
WORKDIR /ko-app
COPY --from=builder /go/src/github.com/kserve/kserve/router /ko-app/
ENTRYPOINT ["/ko-app/router"]
