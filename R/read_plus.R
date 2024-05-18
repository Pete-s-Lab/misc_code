# read multiple csv files and store their filename in column
read_plus <- function(filename) {
  read_csv(filename,
           show_col_types = FALSE) %>% 
    mutate(filename = gsub("\\.csv", "", basename(filename)))
}
