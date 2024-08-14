import gleam/dynamic
import gleam/json

pub type Session {
  Session(id: Int, username: String)
}

pub fn encode(session: Session) {
  json.object([
    #("id", json.int(session.id)),
    #("username", json.string(session.username)),
  ])
  |> json.to_string
}

pub fn decode(session: String) {
  let decoder =
    dynamic.decode2(
      Session,
      dynamic.field("id", of: dynamic.int),
      dynamic.field("username", of: dynamic.string),
    )

  json.decode(from: session, using: decoder)
}
