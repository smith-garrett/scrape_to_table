import gleam/list
import gleam/string
import scrape_to_table/db
import scrape_to_table/html_parsing
import scrape_to_table/http_tools
import sqlight

pub fn main() -> Nil {
  // Note! The BVDG just generates a page for any queried season, so we have to
  // manually constrain ourselves to the valid years for now
  let urls = http_tools.generate_urls(2018, 2026)
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
          case html_parsing.get_all_table_rows(body) {
            Ok(table_rows) ->
              table_rows
              |> list.filter_map(html_parsing.parse_table_entry(_, year))
            Error(_) -> []
          }
        }
        Error(_) -> []
      }
    })

  use sql_connection <- sqlight.with_connection("lifters.sqlite3")
  let sql_command =
    lifter_entries
    |> list.map(html_parsing.text_from_lifter_entry)
    |> generate_sql
  let assert Ok(Nil) = sqlight.exec(sql_command, sql_connection)
  Nil
}

pub fn generate_sql(entries: List(String)) -> String {
  let all_entries = entries |> string.join(",\n") |> fn(x) { x <> ";" }
  "begin transaction;\n"
  <> "create table if not exists lifters (year int, rank int, name string, club string, maximum_points real);
insert into lifters (year, rank, name, club, maximum_points) values"
  <> "\n"
  <> all_entries
  <> "\ncommit;"
}
