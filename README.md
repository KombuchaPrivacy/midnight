# 🐭 Chuckie: Create and redeem tokens for Matrix accounts

Chuckie<sup>[1](#footnote1)</sup> aims to add more advanced membership management features to
Matrix homeservers like [Synapse](https://github.com/matrix-org/synapse).

It is written in the [Swift](https://www.swift.org/) programming language and
the [Vapor](https://vapor.codes/) framework for a nice balance of performance,
concurrency, and built-in memory safety.

## Initial Support
As a first step, Chuckie adds support for token-based signup in the Matrix
[user-interactive authentication API](https://matrix.org/docs/spec/client_server/r0.6.1#id184) (aka the UIAA).

This support is superficially similar to the token-based registration that the
[matrix-registration](https://github.com/ZerataX/matrix-registration) project offers.
However, where matrix-registration uses its own custom protocol, Chuckie complies with
the official Matrix UIAA specification.
Thus it should be more straightforward for clients to add support for Chuckie's
token-based registration.

## How it works
Chuckie sits "in front of" a standard Matrix homeserver like Synapse.
It handles just a few of the Matrix client-server API endpoints.

If you're using a reverse proxy like nginx, you should forward most of the Matrix
API endpoints directly to your "real" homeserver like Synapse.  Forward the
registration-specific endpoints, like `/_matrix/client/(r0|v1)/register`, to Chuckie.

### Footnotes
<a name="footnote1"><sup>1</sup></a> Named for the world's most famous provider
and redeemer of tokens.  The host of many children's birthday parties.  Also, a mouse.
