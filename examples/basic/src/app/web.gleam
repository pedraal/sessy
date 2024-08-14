import app/session.{type Session}
import sessy
import wisp

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request, Result(Session, sessy.SessionError)) ->
    wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  let session = sessy.read_session(req, session.decode)
  case session {
    Ok(s) -> wisp.log_info(s.username <> " request")
    _ -> Nil
  }

  handle_request(req, session)
}
