# add leading zeros
add.leading.zeros <- function(number, length){
  library(stringr)
  str_pad(number, length, pad = "0")
}
