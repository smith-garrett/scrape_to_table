import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/list

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

pub fn new_response_getter() -> HttpResponseGetter {
  let get_fn = fn(url: String) {
    let assert Ok(req) = request.to(url)
    req
    |> request.set_header("User-Agent", "scrape_to_table/1.0 (Educational)")
    |> httpc.send()
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
