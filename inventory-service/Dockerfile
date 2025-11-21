FROM golang:1.20

WORKDIR /app
COPY main.go .

RUN go mod init inventory-mock
RUN go build -o inventory-mock main.go

EXPOSE 8002
CMD ["./inventory-mock"]
