import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result

pub fn main() -> Nil {
  let seasons =
    list.range(2018, 2026)
    |> list.window_by_2
    |> list.map(fn(year_pair) {
      let #(year1, year2) = year_pair
      int.to_string(year1) <> "-" <> int.to_string(year2)
    })

  let base_url =
    "https://german-weightlifting.de/bundesliga/contestants/best-list/"
  let urls = seasons |> list.map(fn(x) { base_url <> x })
  urls |> list.each(get_status)
}

fn get_status(url: String) -> Nil {
  let assert Ok(req) = request.to(url)
  let resp = httpc.send(req)
  case resp {
    Ok(x) -> io.println(url <> ": " <> int.to_string(x.status))
    _ -> io.println("Something when wrong")
  }
}
