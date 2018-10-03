FROM nimlang/nim:alpine as base
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . /usr/app
ARG mc_protocol
ENV MC_PROTOCOL=$mc_protocol
RUN nimble install -y

FROM alpine
COPY --from=base /usr/app/multicart_backend /bin/multicart_backend
CMD ["/bin/multicart_backend"]
