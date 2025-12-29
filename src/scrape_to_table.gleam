import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/list

pub fn main() -> Nil {
  // Note! The BVDG just generates a page for any queried season, so we have to
  // manually constrain ourselves to the valid years for now
  let urls = generate_urls(2018, 2026)
  let getter = new_html_getter()

  urls
  |> list.map(get_html_body(_, getter))
  |> list.each(fn(x) {
    case x {
      Ok(_) -> io.println("Found!")
      _ -> io.println("No body received")
    }
  })
}

pub fn generate_urls(start: Int, end: Int) -> List(String) {
  let seasons =
    list.range(start, end)
    |> list.window_by_2
    |> list.map(fn(year_pair) {
      let #(year1, year2) = year_pair
      int.to_string(year1) <> "-" <> int.to_string(year2)
    })

  let base_url =
    "https://german-weightlifting.de/bundesliga/contestants/best-list/"

  seasons |> list.map(fn(x) { base_url <> x })
}

pub type HttpResponseGetter {
  HtmlGetter(
    get: fn(String) -> Result(response.Response(String), httpc.HttpError),
  )
}

pub fn new_html_getter() -> HttpResponseGetter {
  let get_fn = fn(url: String) {
    let assert Ok(req) = request.to(url)
    httpc.send(req)
  }
  HtmlGetter(get_fn)
}

pub fn get_html_body(
  url: String,
  response_getter: HttpResponseGetter,
) -> Result(String, Nil) {
  let resp = response_getter.get(url)
  case resp {
    Ok(r) -> Ok(r.body)
    _ -> Error(Nil)
  }
}
