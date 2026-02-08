import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup

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
pub fn extract_year_from_url(url: String) -> Int {
  url
  |> string.split("/")
  |> list.last
  |> result.unwrap("")
  |> string.split("-")
  |> list.first
  |> result.try(int.parse)
  |> result.unwrap(0)
}

pub fn get_table_text_from_html_body(body: String) -> List(List(String)) {
  soup.element([soup.with_tag("tbody")])
  |> soup.descendants([soup.with_tag("tr")])
  |> soup.return(soup.text_content())
  |> soup.scrape(body)
  |> result.unwrap([])
  |> list.map(fn(x) { list.filter(x, fn(y) { string.trim(y) != "" }) })
}

// TODO: Write 4 tests: happy, sad (too many entries), sad (too few entries), sad (no tds)
pub fn parse_table_entry(
  table_row: List(String),
  year: Int,
) -> Result(LifterEntry, Nil) {
  case table_row {
    [rank_cell, name_cell, club_cell, points_cell, ..] -> {
      Ok(LifterEntry(
        year: year,
        rank: int.parse(rank_cell) |> result.unwrap(0),
        name: name_cell,
        club: club_cell,
        maximum_points: float.parse(points_cell) |> result.unwrap(0.0),
      ))
    }
    _ -> Error(Nil)
  }
}

pub fn text_from_lifter_entry(lifter_entry: LifterEntry) -> String {
  "("
  <> string.join(
    [
      int.to_string(lifter_entry.year),
      int.to_string(lifter_entry.rank),
      "'" <> lifter_entry.name <> "'",
      "'" <> lifter_entry.club <> "'",
      float.to_string(lifter_entry.maximum_points),
    ],
    ", ",
  )
  <> ")"
}
