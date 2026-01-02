import gleeunit/should
import scrape_to_table/db
import scrape_to_table/html_parsing
import sqlight

pub fn insert_lifters_test() {
  let lifter_entries = [
    html_parsing.Entry(2025, 1, "abc", "club1", 100.0),
    html_parsing.Entry(2025, 2, "def", "club2", 101.0),
  ]
  use sql_connection <- sqlight.with_connection(":memory:")
  assert Nil == db.insert_lifters(lifter_entries, sql_connection)
}
