# 1.0.4

- Fail server if `PROTOCOL` env var is unset.


# 1.0.3

- Fix fatal issue on Linux when the server would crash on websocket close.


# 1.0.2

- Switch back to oids, because hashids requires pcre, and that's too much than I want to drag into  deployment.


# 1.0.1

- Switch from oids to hashids for customer IDs.


# 1.0.0

- Initial release.
