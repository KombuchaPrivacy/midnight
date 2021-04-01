# AURIC: A User Registration Interactive Controller

Auric<sup>[1](#footnote1)</sup> adds more advanced membership management features to
Matrix homeservers like [Synapse](https://github.com/matrix-org/synapse).

It is written in the [Swift](https://www.swift.org/) programming language and
the [Vapor](https://vapor.codes/) framework for a nice balance of performance,
concurrency, and built-in memory safety.

## Initial Support
As a first step, Auric adds support for token-based authentication in the Matrix
[user-interactive authentication API](https://matrix.org/docs/spec/client_server/r0.6.1#id184) (aka the UIAA).

This support is superficially similar to the token-based registration that the
[matrix-registration](https://github.com/ZerataX/matrix-registration) project offers.
However, where matrix-registration uses its own custom protocol, Auric complies with
the official Matrix UIAA specification.
Thus it should be more straightforward for clients to add support for Auric's
token-based registration.

## Next Steps
Planned features include support for controlling the number of users allowed in a room
or the number of rooms that a user is allowed to create.

## How it works
Auric sits "in front of" a standard Matrix homeserver like Synapse.
It handles just a few of the Matrix client-server API endpoints, mostly related to
the creation of accounts and rooms, and to invites.

If you're using a reverse proxy like nginx, you should forward most of the Matrix
API endpoints directly to your "real" homeserver like Synapse.  Forward the other
endpoints, like `/_matrix/client/(r0|v1)/register`, to Auric.

### Footnotes
<a name="footnote1"><sup>1</sup></a> The name is a sort of double play on words.
**Goldmember** is one of the villains in the Austin Powers movies.
He runs a nightclub, and you have to be a *gold member* to enter his club, see?
So the movie title isn't a puerile anatomical joke at all.
*Ahem*.  Riiiiight.
Anyway, I'm not about to name a software project "Goldmember", so instead it's
named after Auric Goldfinger from the 007 films, who was the inspiration for
the Goldmember character and the associated juvenile humor.

Alternatively: A User Registration Interactive Controller
