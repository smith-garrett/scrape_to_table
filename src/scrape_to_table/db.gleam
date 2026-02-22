import gleam/dynamic/decode
import gleam/list
import scrape_to_table/html_parsing
import sqlight

pub fn insert_lifters(
  lifter_entries: List(html_parsing.LifterEntry),
  sql_connection: sqlight.Connection,
) -> Nil {
  let assert Ok(_) = create_db(sql_connection)
  let assert Ok(_) = sqlight.exec("begin transaction", sql_connection)

  let insert_query =
    "insert into lifters (year, rank, name, club, maximum_points) values (?, ?, ?, ?, ?)"

  let _ =
    lifter_entries
    |> list.map(fn(entry) {
      sqlight.query(
        insert_query,
        sql_connection,
        [
          sqlight.int(entry.year),
          sqlight.int(entry.rank),
          sqlight.text(entry.name),
          sqlight.text(entry.club),
          sqlight.float(entry.maximum_points),
        ],
        decode.success(Nil),
      )
    })
  let assert Ok(_) = sqlight.exec("commit", sql_connection)
  Nil
}

fn create_db(sql_connection: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  let cmd =
    "create table if not exists lifters (year integer, rank integer, name text, club text, maximum_points real);"
  sqlight.exec(cmd, sql_connection)
}
