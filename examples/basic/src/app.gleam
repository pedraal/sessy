import app/router
import gleam/erlang/process
import mist
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = "set_me_in_production!!!"

  let assert Ok(_) =
    wisp.mist_handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
