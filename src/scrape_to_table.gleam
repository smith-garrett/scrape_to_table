import gleam/io
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup
import scrape_to_table/db
import scrape_to_table/html_parsing
import scrape_to_table/http_tools
import sqlight

pub fn main() -> Nil {
  // Note! The BVDG just generates a page for any queried season, so we have to
  // manually constrain ourselves to the valid years for now
  let urls = http_tools.generate_urls(2018, 2025)
  let getter = http_tools.new_response_getter()

  // Pair each URL with its year
  let url_year_pairs =
    urls
    |> list.map(fn(url) {
      let year = html_parsing.extract_year_from_url(url)
      #(url, year)
    })

  let lifter_entries =
    url_year_pairs
    |> list.flat_map(fn(pair) {
      let #(url, year) = pair
      case http_tools.get_html_body(url, getter) {
        Ok(body) -> {
          body
          |> html_parsing.get_table_text_from_html_body()
          |> list.filter_map(fn(x) { html_parsing.parse_table_entry(x, year) })
          |> echo
        }
        Error(_) -> []
      }
    })

  use sql_connection <- sqlight.with_connection("lifters.sqlite3")
  db.insert_lifters(lifter_entries, sql_connection)
}
