FROM nimlang/nim:alpine as base
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . /usr/app
RUN nimble install -y

FROM alpine
COPY --from=base /usr/app/buddyshopping /bin/buddyshopping
CMD ["/bin/buddyshopping"]
