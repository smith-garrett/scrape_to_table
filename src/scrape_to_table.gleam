import gleam/float
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup

pub fn main() -> Nil {
  // Note! The BVDG just generates a page for any queried season, so we have to
  // manually constrain ourselves to the valid years for now
  let start_year = 2018
  let end_year = 2025 + 1
  let urls = generate_urls(start_year, end_year + 1)
  let getter = new_response_getter()

  let html_bodies =
    urls
    |> list.map(get_html_body(_, getter))
    |> result.values
    |> list.strict_zip(list.range(start_year, end_year))

  let entries =
    html_bodies
    |> list.flat_map(fn(body) {
      case get_all_table_entries(body) {
        Ok(trs) -> trs |> list.filter_map(parse_table_entry)
        Error(_) -> []
      }
    })

  // Print the parsed entries
  entries
  |> list.each(fn(entry) {
    io.println(
      "Rank: "
      <> int.to_string(entry.rank)
      <> ", Name: "
      <> entry.name
      <> ", Club: "
      <> entry.club
      <> ", Points: "
      <> float.to_string(entry.maximum_points),
    )
  })

  Nil
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

pub fn new_response_getter() -> HttpResponseGetter {
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

// TODO: write tests
pub fn get_all_table_entries(html_body) -> Result(List(soup.Element), Nil) {
  let query =
    soup.element([soup.tag("tbody")])
    |> soup.descendant([soup.tag("tr")])
  soup.find_all(html_body, query)
}

pub type Entry {
  Entry(year: Int, rank: Int, name: String, club: String, maximum_points: Float)
}

// TODO: Write 2 tests: one with an embedded child, one without
// Extract text content from an element and its children
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
fn get_td_elements(tr_element: soup.Element) -> Result(List(soup.Element), Nil) {
  case tr_element {
    soup.Element(_tag, _attrs, children) -> {
      let tds =
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

      case list.is_empty(tds) {
        True -> Error(Nil)
        False -> Ok(tds)
      }
    }
    soup.Text(_) -> Error(Nil)
  }
}

// TODO: Write 4 tests: happy, sad (too many entries), sad (too few entries), sad (no tds)
pub fn parse_table_entry(tr_element: soup.Element) -> Result(Entry, Nil) {
  case get_td_elements(tr_element) {
    Ok(tds) -> {
      // The table has columns: Rank, Name, Club, Maximum Points
      case tds {
        [rank_td, name_td, club_td, points_td, ..] -> {
          let rank_text = get_text_content(rank_td)
          let name_text = get_text_content(name_td)
          let club_text = get_text_content(club_td)
          let points_text = get_text_content(points_td)

          // Parse rank as int
          let rank = int.parse(rank_text) |> result.unwrap(0)

          // Parse points as float (might have comma as decimal separator)
          let points_normalized = string.replace(points_text, ",", ".")
          let points = float.parse(points_normalized) |> result.unwrap(0.0)

          Ok(Entry(
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
