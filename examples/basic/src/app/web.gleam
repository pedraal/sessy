import app/session.{type Session}
import gleam/option
import wisp
import wisp_session

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request, option.Option(Session)) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  let session = wisp_session.read_session(req, session.decode)
  case session {
    option.Some(s) -> wisp.log_info(s.username <> " request")
    _ -> Nil
  }

  handle_request(req, session)
}
