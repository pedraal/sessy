import app/session.{type Session, Session}
import app/web
import gleam/http.{Delete, Get, Post}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string_builder
import sessy
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req, user_session <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home(req, user_session)
    ["session"] -> session_handler(req)
    _ -> wisp.not_found()
  }
}

pub fn home(_req, session: Option(Session)) -> Response {
  case session {
    Some(s) -> {
      [
        "<h1>Hello, "
          <> wisp.escape_html(s.username)
          <> "#"
          <> int.to_string(s.id)
          <> "!</h1>",
        "<form action='/session?_method=DELETE' method='post'>",
        "  <button type='submit'>Log out</button>",
        "</form>",
      ]
      |> string_builder.from_strings
      |> wisp.html_response(200)
    }
    None -> {
      wisp.redirect("/session")
    }
  }
}

pub fn session_handler(req: Request) -> Response {
  case req.method {
    Get -> new_session(req)
    Post -> create_session(req)
    Delete -> destroy_session(req)
    _ -> wisp.method_not_allowed([Get, Post, Delete])
  }
}

pub fn new_session(req) -> Response {
  use <- sessy.require_no_session(req, session.decode)
  "
  <form action='/session' method='post'>
    <label>
      Username: <input type='text' name='username'>
    </label>
    <button type='submit'>Log in</button>
  </form>
  "
  |> string_builder.from_string
  |> wisp.html_response(200)
}

pub fn create_session(req: Request) -> Response {
  use <- sessy.require_no_session(req, session.decode)
  use formdata <- wisp.require_form(req)

  case list.key_find(formdata.values, "username") {
    Ok(username) -> {
      wisp.redirect("/")
      |> sessy.set_session(
        req,
        session.encode(Session(username:, id: 123)),
        365 * 24 * 60 * 60,
      )
    }
    Error(_) -> {
      wisp.redirect("/session")
    }
  }
}

pub fn destroy_session(req: Request) -> Response {
  use _ <- sessy.require_session(req, session.decode)

  wisp.redirect("/session")
  |> sessy.clear_session(req)
}
