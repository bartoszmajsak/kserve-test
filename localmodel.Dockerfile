# Build the manager binary
FROM golang:1.25 AS builder

# Copy in the go src
WORKDIR /go/src/github.com/kserve/kserve
COPY go.mod  go.mod
COPY go.sum  go.sum

RUN go mod download

COPY cmd/localmodel/ cmd/localmodel/
COPY pkg/    pkg/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOFLAGS=-mod=readonly go build -a -o localmodel-manager ./cmd/localmodel

# Generate third-party licenses
COPY LICENSE LICENSE
RUN go install github.com/google/go-licenses@latest && \
    go-licenses check ./cmd/localmodel ./pkg/... --disallowed_types="forbidden,unknown" && \
    go-licenses save --save_path third_party/library ./cmd/localmodel

# Copy the controller-manager into a thin image
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /go/src/github.com/kserve/kserve/third_party /third_party
COPY --from=builder /go/src/github.com/kserve/kserve/localmodel-manager /manager
ENTRYPOINT ["/manager"]
