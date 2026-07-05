FROM golang:1.24-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY agent/main.go ./agent/main.go
RUN CGO_ENABLED=0 go build -o /out/agent ./agent

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/agent /agent
ENTRYPOINT ["/agent"]
