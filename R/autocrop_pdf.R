# Check if pdfcrop is installed 
# * Linux: sudo apt install texlive-extra-utils
# * Windows: install TeX Live
# * macOS: installed with MacTeX

# Check:
  # pdfcrop --version

auto_crop_pdf <- function(infile, outfile, margin = 5) {
  cmd <- sprintf('pdfcrop --margins "%d %d %d %d" %s %s',
                 margin, margin, margin, margin,
                 shQuote(infile), shQuote(outfile))
  system(cmd)
  message("Wrote cropped PDF to: ", outfile)
}


figs_folder <- "X:/Pub/_Diss/MS/Figs/Figs_fin/PCA"

files_in <- list.files(figs_folder,
                       pattern = "\\.pdf$",
                       full.names = TRUE)

i=1
file_in <- files_in[i]
for(file_in in files_in){
  # file_in <- file.path(figs_folder,
  #                      paste0("PCA_bite_shape_head_conf_phylocorr_phylomorphospace_deg6_PC1_PC2_V7_1", 
  #                             ".pdf"))
  cat(file_in, "\n",
      i, "/", length(files_in))
  file_out <- gsub("\\.pdf$", "_cr.pdf", file_in)
  
  auto_crop_pdf(infile = file_in,
                outfile = file_out,
                margin = 4)
}
