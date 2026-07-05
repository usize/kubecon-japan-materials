FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY agent/main.go ./agent/main.go
RUN CGO_ENABLED=0 go build -o /out/agent ./agent

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/agent /agent
ENTRYPOINT ["/agent"]
