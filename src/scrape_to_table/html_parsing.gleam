import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup

// TODO: write tests
pub fn get_all_table_rows(html_body) -> Result(List(soup.Element), Nil) {
  let query =
    soup.element([soup.tag("tbody")])
    |> soup.descendant([soup.tag("tr")])
  soup.find_all(html_body, query)
}

pub type LifterEntry {
  Entry(year: Int, rank: Int, name: String, club: String, maximum_points: Float)
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

// TODO: Write 2 tests: one with an embedded child, one without
fn get_text_content(element: soup.Element) -> String {
  case element {
    soup.Element(_tag, _attrs, children) -> {
      children
      |> list.map(fn(child) {
        case child {
          soup.Element(_, _, _) -> get_text_content(child)
          soup.Text(text) -> text
        }
      })
      |> string.join("")
      |> string.trim
    }
    soup.Text(text) -> string.trim(text)
  }
}

// TODO: Write 3 tests: happy, sad (no tds), sad (only Text)
// Get all td elements from a tr
fn get_table_cell_elements(
  table_row_element: soup.Element,
) -> Result(List(soup.Element), Nil) {
  case table_row_element {
    soup.Element(_tag, _attrs, children) -> {
      let table_cells =
        children
        |> list.filter(fn(child) {
          case child {
            soup.Element(tag, _, _) -> tag == "td"
            soup.Text(_) -> False
          }
        })
        |> list.map(fn(child) {
          case child {
            soup.Element(_, _, _) as el -> el
            soup.Text(_) -> soup.Element("", [], [])
          }
        })

      case list.is_empty(table_cells) {
        True -> Error(Nil)
        False -> Ok(table_cells)
      }
    }
    soup.Text(_) -> Error(Nil)
  }
}

// TODO: Write 4 tests: happy, sad (too many entries), sad (too few entries), sad (no tds)
pub fn parse_table_entry(
  table_row_element: soup.Element,
  year: Int,
) -> Result(LifterEntry, Nil) {
  case get_table_cell_elements(table_row_element) {
    Ok(table_cells) -> {
      // The table has columns: Rank, Name, Club, Maximum Points
      case table_cells {
        [rank_cell, name_cell, club_cell, points_cell, ..] -> {
          let rank_text = get_text_content(rank_cell)
          let name_text = get_text_content(name_cell)
          let club_text = get_text_content(club_cell)
          let points_text = get_text_content(points_cell)

          let rank = int.parse(rank_text) |> result.unwrap(0)

          let points = float.parse(points_text) |> result.unwrap(0.0)

          Ok(Entry(
            year: year,
            rank: rank,
            name: name_text,
            club: club_text,
            maximum_points: points,
          ))
        }
        _ -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
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
