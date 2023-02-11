import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/option.{None, Option}

pub type SimpleHttpBuilder(body) {
  SimpleHttpBuilder(
    /// Function that is applied to the `base_request` before being passed
    /// to the `req` function
    setup_request: Option(fn(Request(body)) -> Request(body)),
    /// Base request for contant values e.g. auth headers
    base_request: Option(Request(body)),
    /// Initial value for request body, e.g. `""`
    initial_req_body: body,
    /// Function that sends a request and gets a response
    sender: fn(Request(body)) -> Response(body),
  )
}

pub type SimpleHttp(body) {
  SimpleHttp(
    setup_request: fn(Request(body)) -> Request(body),
    base_request: Request(body),
    sender: fn(Request(body)) -> Response(body),
  )
}

pub fn new_builder(
  sender: fn(Request(body)) -> Response(body),
  initial_request_body: body,
) -> SimpleHttpBuilder(body) {
  SimpleHttpBuilder(
    setup_request: None,
    base_request: None,
    sender: sender,
    initial_req_body: initial_request_body,
  )
}

/// Creates a default SimpleHttp client
pub fn default(
  sender: fn(Request(body)) -> Response(body),
  initial_request_body: body,
) -> SimpleHttp(body) {
  new(new_builder(sender, initial_request_body))
}

/// Creates a new SimpleHttp client, taking overrides from the
/// SimpleHttpBuilder
pub fn new(builder: SimpleHttpBuilder(body)) -> SimpleHttp(body) {
  SimpleHttp(
    setup_request: option.unwrap(builder.setup_request, or: fn(r) { r }),
    base_request: option.unwrap(
      builder.base_request,
      Request(
        method: Get,
        headers: [],
        body: builder.initial_req_body,
        scheme: http.Https,
        host: "localhost",
        port: option.None,
        path: "",
        query: option.None,
      ),
    ),
    sender: builder.sender,
  )
}

/// Sends a request via the client's `sender`, the flow is as follows:
/// 1. Take client's `base_request`
/// 2. Pass to the `setup_request` function
/// 3. Pass to the `request` parameter
/// 4. Return the reponse from `sender`
pub fn req(
  client: SimpleHttp(body),
  request: fn(Request(body)) -> Request(body),
) {
  client.base_request
  |> client.setup_request
  |> request
  |> client.sender
}
