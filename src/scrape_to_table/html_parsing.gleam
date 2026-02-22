import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup
import woof as log

pub type LifterEntry {
  LifterEntry(
    year: Int,
    rank: Int,
    name: String,
    club: String,
    maximum_points: Float,
  )
}

// TODO: Write 3 tests: happy, sad (nothing after the /), sad (non-integers after /)
pub fn extract_year_from_url(url: String) -> Result(Int, Nil) {
  url
  |> string.split("/")
  |> list.last
  |> result.unwrap("")
  |> string.split("-")
  |> list.first
  |> result.try(int.parse)
  // |> result.lazy_unwrap(fn() {
  //   log.warning("Year not found. Replacing with 0.", [])
  //   0
  // })
}

pub fn get_table_text_from_html_body(body: String) -> List(List(String)) {
  soup.element([soup.with_tag("tbody")])
  |> soup.descendants([soup.with_tag("tr")])
  |> soup.return(soup.text_content())
  |> soup.scrape(body)
  |> result.unwrap([])
  |> list.map(fn(x) { list.filter(x, fn(y) { string.trim(y) != "" }) })
}

pub fn parse_table_entry(
  table_row: List(String),
  year: Int,
) -> Result(LifterEntry, Nil) {
  case table_row {
    [rank_cell, name_cell, club_cell, points_cell, ..] -> {
      case int.parse(rank_cell), float.parse(points_cell) {
        Ok(r), Ok(pts) ->
          Ok(LifterEntry(
            year: year,
            rank: r,
            name: name_cell,
            club: club_cell,
            maximum_points: pts,
          ))
        _, _ -> {
          log.warning("Could not parse rank or points", [
            #("rank", rank_cell),
            #("points", points_cell),
          ])
          Error(Nil)
        }
      }
    }
    _ -> {
      log.warning("Table row in unexpected format", [])
      Error(Nil)
    }
  }
}
