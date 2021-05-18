# Midnight Tokens: Create and redeem tokens for Matrix accounts

Midnight<sup>[1](#footnote1)</sup> aims to add more advanced membership management features to
Matrix homeservers like [Synapse](https://github.com/matrix-org/synapse).

It is written in the [Swift](https://www.swift.org/) programming language and
the [Vapor](https://vapor.codes/) framework for a nice balance of performance,
concurrency, and built-in memory safety.

## Initial Support
As a first step, Midnight adds support for token-based signup in the Matrix
[user-interactive authentication API](https://matrix.org/docs/spec/client_server/r0.6.1#id184) (aka the UIAA).

This support is superficially similar to the token-based registration that the
[matrix-registration](https://github.com/ZerataX/matrix-registration) project offers.
However, where matrix-registration uses its own custom API, Midnight complies with
the official Matrix UIAA specification.
Thus it should be more straightforward for Matrix clients to add support for Midnight's
token-based registration.

## How it works
Midnight sits "in front of" a standard Matrix homeserver like [Synapse](https://github.com/matrix-org/synapse)
or [Conduit](https://conduit.rs/).
It handles just a few of the Matrix client-server API endpoints.

If you're using a reverse proxy like nginx, you should forward most of the Matrix
API endpoints directly to your "real" homeserver like Synapse.  Forward the
registration-specific endpoints, like `/_matrix/client/(r0|v1)/register`, to Midnight.

### Footnotes
<a name="footnote1"><sup>1</sup></a> Yes, the name is a silly reference to an old Steve Miller Band song.
