import gleeunit/should
import scrape_to_table/html_parsing

pub fn extract_year_from_url_happy_test() {
  html_parsing.extract_year_from_url("https://example.com/2023-2024")
  |> should.equal(Ok(2023))
}

pub fn extract_year_from_url_no_slash_test() {
  html_parsing.extract_year_from_url("https://example.com")
  |> should.be_error()
  // Or consider should.be_error if returning Result
}

pub fn extract_year_from_url_invalid_year_test() {
  html_parsing.extract_year_from_url("https://example.com/abc-def")
  |> should.be_error()
}

pub fn parse_table_entry_happy_test() {
  html_parsing.parse_table_entry(["1", "John Doe", "Club A", "95.5"], 2024)
  |> should.be_ok
  |> should.equal(html_parsing.LifterEntry(
    year: 2024,
    rank: 1,
    name: "John Doe",
    club: "Club A",
    maximum_points: 95.5,
  ))
}

pub fn parse_table_entry_too_few_entries_test() {
  html_parsing.parse_table_entry(["1", "John"], 2024)
  |> should.be_error
}

pub fn parse_table_entry_invalid_rank_test() {
  html_parsing.parse_table_entry(["abc", "John Doe", "Club A", "95.5"], 2024)
  |> should.be_error
}

pub fn parse_table_entry_invalid_points_test() {
  html_parsing.parse_table_entry(["1", "John Doe", "Club A", "abc"], 2024)
  |> should.be_error
}
