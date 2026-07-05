FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY tainted-server/main.go ./tainted-server/main.go
RUN CGO_ENABLED=0 go build -o /out/tainted-server ./tainted-server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/tainted-server /tainted-server
EXPOSE 9999
ENTRYPOINT ["/tainted-server"]
