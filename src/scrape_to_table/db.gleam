import gleam/list
import gleam/string
import scrape_to_table/html_parsing
import sqlight

pub fn insert_lifters(
  lifter_entries: List(html_parsing.LifterEntry),
  sql_connection: sqlight.Connection,
) -> Nil {
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
