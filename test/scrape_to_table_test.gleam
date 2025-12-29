import gleeunit
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
