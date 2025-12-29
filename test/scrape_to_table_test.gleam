import gleam/http/response
import gleam/httpc
import gleeunit
import gleeunit/should
import scrape_to_table

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn generate_urls_test() {
  let urls_one_season = scrape_to_table.generate_urls(1, 2)
  assert urls_one_season
    == ["https://german-weightlifting.de/bundesliga/contestants/best-list/1-2"]
  let urls_two_seasons = scrape_to_table.generate_urls(1, 3)
  assert urls_two_seasons
    == [
      "https://german-weightlifting.de/bundesliga/contestants/best-list/1-2",
      "https://german-weightlifting.de/bundesliga/contestants/best-list/2-3",
    ]
}

fn good_html_getter() -> scrape_to_table.HttpResponseGetter {
  let getter = fn(_not_used: String) {
    Ok(response.Response(200, [#("abc", "def")], "test_body"))
  }
  scrape_to_table.HtmlGetter(getter)
}

fn bad_html_getter() -> scrape_to_table.HttpResponseGetter {
  let getter = fn(_not_used: String) { Error(httpc.ResponseTimeout) }
  scrape_to_table.HtmlGetter(getter)
}

pub fn get_html_body_test() {
  scrape_to_table.get_html_body("https://fake.com", good_html_getter())
  |> should.be_ok

  scrape_to_table.get_html_body("https://fake.com", bad_html_getter())
  |> should.be_error
}
