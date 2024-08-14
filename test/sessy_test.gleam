import gleam/crypto
import gleam/dict
import gleam/http/response
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import sessy
import wisp
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn set_session_test() {
  let request = testing.get("/", [])

  let response =
    wisp.redirect("/")
    |> sessy.set_session(request, "123;john_doe", 365 * 24 * 60 * 60)

  let cookies =
    response.get_cookies(response)
    |> dict.from_list

  cookies
  |> dict.has_key("wisp_session")
  |> should.equal(True)
}

pub fn clear_session_test() {
  let request =
    testing.get("/", [])
    |> testing.set_cookie("wisp_session", "123", wisp.Signed)

  let cookie_value =
    wisp.redirect("/")
    |> sessy.clear_session(request)
    |> response.get_cookies
    |> dict.from_list
    |> dict.get("wisp_session")
    |> result.unwrap("")

  wisp.sign_message(request, <<"":utf8>>, crypto.Sha512)
  |> should.equal(cookie_value)
}

pub fn read_session_with_valid_cookie_test() {
  let request =
    testing.get("/", [])
    |> testing.set_cookie("wisp_session", "123;john_doe", wisp.Signed)

  sessy.read_session(request, decode_session)
  |> should.equal(Ok(["123", "john_doe"]))
}

pub fn read_session_with_invalid_cookie_test() {
  let request =
    testing.get("/", [])
    |> testing.set_cookie("wisp_session", "lorem", wisp.Signed)

  sessy.read_session(request, decode_session)
  |> should.equal(Error(sessy.SessionInvalid))
}

pub fn read_session_with_missing_cookie_test() {
  let request = testing.get("/", [])

  sessy.read_session(request, decode_session)
  |> should.equal(Error(sessy.SessionMissing))
}

pub fn require_session_test() {
  let request = testing.get("/", [])
  let response =
    sessy.require_session(request, decode_session, fn(_b) { wisp.ok() })

  response.status
  |> should.equal(401)

  let request =
    testing.get("/", [])
    |> testing.set_cookie("wisp_session", "123;john_doe", wisp.Signed)
  let response =
    sessy.require_session(request, decode_session, fn(_b) { wisp.ok() })

  response.status
  |> should.equal(200)
}

pub fn require_no_session_test() {
  let request = testing.get("/", [])
  let response =
    sessy.require_no_session(request, decode_session, fn() { wisp.ok() })

  response.status
  |> should.equal(200)

  let request =
    testing.get("/", [])
    |> testing.set_cookie("wisp_session", "123;john_doe", wisp.Signed)
  let response =
    sessy.require_no_session(request, decode_session, fn() { wisp.ok() })

  response.status
  |> should.equal(403)
}

fn decode_session(str: String) {
  case string.split(str, ";") {
    [id, username] -> Ok([id, username])
    _ -> Error(Nil)
  }
}
