# sessy

sessy is a set of utilities for using cookie-based sessions with the wisp web framework

[![Package Version](https://img.shields.io/hexpm/v/sessy)](https://hex.pm/packages/sessy)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sessy/)

## Setting a user session
In sessy, session cookie is signed using the wisp secret_key_base.
All you need is to give sessy an encoding function that returns a stringified version of your data structure.
Here is an example of a JSON based session :
```gleam
pub type Session {
  Session(id: Int, username: String)
}

pub fn encode_session(session: Session) {
  json.object([
    #("id", json.int(session.id)),
    #("username", json.string(session.username)),
  ])
  |> json.to_string
}

fn login_handler(req) {
  use user <- login(req)
  wisp.redirect("/")
  |> sessy.set_session(
    req,
    encode_session(Session(id: user.id, username: user.username)),
    365 * 24 * 60 * 60,
  )
}

fn logout_handler(req) {
  wisp.redirect("/session")
  |> sessy.clear_session(req)
}
```

## Reading a user session
Using the previous JSON based session data structure, you can decode user's session like this:
```gleam
pub type Session {
  Session(id: Int, username: String)
}

pub fn decode(session: String) {
  let decoder =
    dynamic.decode2(
      Session,
      dynamic.field("id", of: dynamic.int),
      dynamic.field("username", of: dynamic.string),
    )

  json.decode(from: session, using: decoder)
  |> option.from_result
}

fn posts_handler(req) {
  let session = sessy.read_session(req, decode)
  // do something with session
}
```

## User session guard
At some point of your application you will probably need to ensure a user has a session or not.
For this, you can use `sessy.require_session` and `sessy.require_no_session` middlewares. They will respectively return a 401 and 403 if condition is not met.

```gleam
// For a set of routes
case wisp.path_segments(req) {
  ["admin",..] -> {
    use session <- sessy.require_session(req, decode_session)
    case wisp.path_segments(req) {
      ["admin", "users"] -> users_page(req)
      ["admin", "posts"] -> posts_page(req)
    }
  }
}

// For a single route
fn login_page(req) {
  use <- sessy.require_no_session(req)
  // render a login page
}
```
