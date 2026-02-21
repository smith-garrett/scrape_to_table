import gleam/list
import gleam/string
import scrape_to_table/html_parsing
import sqlight

pub fn insert_lifters(
  lifter_entries: List(html_parsing.LifterEntry),
  sql_connection: sqlight.Connection,
) -> Nil {
  let assert Ok(_) = create_db(sql_connection)
  let sql_command =
    lifter_entries
    |> list.map(html_parsing.text_from_lifter_entry)
    |> generate_sql
  let assert Ok(Nil) = sqlight.exec(sql_command, sql_connection)
  Nil
}

fn create_db(sql_connection: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  let cmd =
    "create table if not exists lifters (year integer, rank integer, name text, club text, maximum_points real);"
  sqlight.exec(cmd, sql_connection)
}

pub fn generate_sql(entries: List(String)) -> String {
  let all_entries = entries |> string.join(",\n") |> fn(x) { x <> ";" }
  "begin transaction;\n"
  <> "insert into lifters (year, rank, name, club, maximum_points) values"
  <> "\n"
  <> all_entries
  <> "\ncommit;"
}
