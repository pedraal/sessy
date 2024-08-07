# wisp_session

wisp_session is a set of utilities for using cookie-based user sessions with the wisp web framework

[![Package Version](https://img.shields.io/hexpm/v/wisp_session)](https://hex.pm/packages/wisp_session)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/wisp_session/)

## Setting a user session
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
  |> wisp_session.set_session(
    req,
    encode_session(Session(id: user.id, username: user.username)),
    365 * 24 * 60 * 60,
  )
}

fn logout_handler(req) {
  wisp.redirect("/session")
  |> wisp_session.clear_session(req)
}
```

## Reading a user session
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
  let session = wisp_session.read_session(req, decode)
  // do something with session
}
```

## User session guard
At some point of your application you will probably need to ensure a user has a session or not.
For this, you can use `wisp_session.require_session` and `wisp_session.require_no_session` middlewares. They will respectively return a 401 and 403 if condition is not met.

```gleam
// For a set of routes
case wisp.path_segments(req) {
  ["admin",..] -> {
    use session <- wisp_session.require_session(req, decode_session)
    case wisp.path_segments(req) {
      ["admin", "users"] -> users_page(req)
      ["admin", "posts"] -> posts_page(req)
    }
  }
}

// For a single route
fn login_page(req) {
  use <- wisp_session.require_no_session(req)
  // render a login page
}
```
