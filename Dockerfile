FROM nimlang/nim:latest-alpine-onbuild as base

FROM alpine
COPY --from=base /usr/src/app/multicart_backend /bin/multicart_backend
CMD ["/bin/multicart_backend"]
