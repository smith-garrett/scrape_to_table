import gleam/dynamic/decode
import scrape_to_table/db
import scrape_to_table/html_parsing
import sqlight

pub fn insert_lifters_test() {
  let entry1 = #(2025, 1, "abc", "club1", 100.0)
  let entry2 = #(2025, 2, "def", "club2", 101.0)
  let lifter_entries = [
    html_parsing.LifterEntry(2025, 1, "abc", "club1", 100.0),
    html_parsing.LifterEntry(2025, 2, "def", "club2", 101.0),
  ]
  use sql_connection <- sqlight.with_connection(":memory:")
  assert Nil == db.insert_lifters(lifter_entries, sql_connection)

  let lifters_decoder = {
    use year <- decode.field(0, decode.int)
    use rank <- decode.field(1, decode.int)
    use name <- decode.field(2, decode.string)
    use club <- decode.field(3, decode.string)
    use maximum_points <- decode.field(4, decode.float)
    decode.success(#(year, rank, name, club, maximum_points))
  }
  let query = "select * from lifters"
  assert Ok([entry1, entry2])
    == sqlight.query(query, sql_connection, [], lifters_decoder)
}
