FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY news-server/main.go ./news-server/main.go
RUN CGO_ENABLED=0 go build -o /out/news-server ./news-server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/news-server /news-server
EXPOSE 8888
ENTRYPOINT ["/news-server"]
