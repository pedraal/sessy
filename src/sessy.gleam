import gleam/http/response.{Response as HttpResponse}
import gleam/result
import wisp.{type Request, type Response}

pub type SessionError {
  SessionMissing
  SessionInvalid
}

/// Set the session cookie
/// Session value must be encoded to string
/// # Examples
/// ```gleam
/// pub type Session {
///   Session(id: Int, username: String)
/// }
///
/// pub fn encode_session(session: Session) -> String {
///   // Your encoder implementation
/// }
/// ...
/// wisp.ok()
/// |> sessy.set_session(
///   req,
///   encode_session(Session(id: 123, username: "john_doe")),
///   365 * 24 * 60 * 60
/// )
/// ```
///
pub fn set_session(
  response: Response,
  request: Request,
  session: String,
  expiration: Int,
) {
  response
  |> wisp.set_cookie(request, "wisp_session", session, wisp.Signed, expiration)
}

/// Clear the session cookie
/// # Examples
/// ```gleam
/// wisp.redirect("/")
/// |> sessy.clear_session(req)
/// ```
pub fn clear_session(response: Response, request: Request) {
  set_session(response, request, "", 0)
}

/// Get and decode a session, returning a Some with decoded
/// session if session found, or None if not
/// # Examples
/// ```gleam
/// pub type Session {
///   Session(id: Int, username: String)
/// }
///
/// pub fn decode_session(session: String) -> Option(Session) {
///   // Your decoder implementation
/// }
///
/// let session = sessy.require_session(req, decode_session)
/// ```
///
pub fn read_session(request: Request, decoder: fn(String) -> Result(a, b)) {
  let cookie = wisp.get_cookie(request, "wisp_session", wisp.Signed)

  case result.map(cookie, decoder) {
    Ok(Ok(session)) -> Ok(session)
    Ok(Error(_)) -> Error(SessionInvalid)
    Error(_) -> Error(SessionMissing)
  }
}

/// This middleware will get and decode a session
/// an empty response with status code 401: unauthorized
/// is returned if no session found
/// # examples
/// ```gleam
/// pub type Session {
///   Session(id: Int, username: String)
/// }
///
/// pub fn decode_session(session: String) -> Session {
///   // your decoder implementation
/// }
///
/// ...
/// use session <- sessy.require_session(req, decode_session)
/// ```
///
pub fn require_session(
  request: Request,
  decoder: fn(String) -> Result(a, b),
  next: fn(a) -> Response,
) -> Response {
  let session = read_session(request, decoder)
  case session {
    Ok(decoded) -> next(decoded)
    _ -> HttpResponse(401, [], wisp.Empty)
  }
}

/// This middleware will return a 403 Forbidden response
/// if a cookie session is found and decoded successfully,
/// or will proceed
/// # examples
/// ```gleam
/// pub type Session {
///   Session(id: Int, username: String)
/// }
///
/// pub fn decode_session(session: String) -> Session {
///   // your decoder implementation
/// }
///
/// ...
/// use <- sessy.require_session(req, decode_session)
/// ```
///
pub fn require_no_session(
  request: Request,
  decoder: fn(String) -> Result(a, b),
  next: fn() -> Response,
) -> Response {
  let session = read_session(request, decoder)
  case session {
    Ok(_) -> HttpResponse(403, [], wisp.Empty)
    _ -> next()
  }
}
