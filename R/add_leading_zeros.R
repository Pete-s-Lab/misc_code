# add leading zeros
add.leading.zeros <- function(number, length){
  str_pad(number, length, pad = "0")
}
