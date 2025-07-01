# downloads gene sequences from NCBI and BOLD
# PT Rühr 2025-07-01
# v.0.0.9016

library(rentrez)
library(seqinr)
library(xml2)

# -------- PARAMETERS ---------

taxa <- c("Zoraptera", "Dermaptera", "Embioptera")
genes <- c("COI", "16S", "28S", "H3", "wingless", "CAD")
retmax <- 5000
gene_min_lengths <- list(
  "COI"       = 500,
  "16S"       = 300,
  "28S"       = 600,
  "H3"        = 250,
  "wingless"  = 300,
  "CAD"       = 600
)

max_length <- 4000
output_dir <- "ncbi_bold_downloads"
batch_size <- 300
sleep_time <- 0.3

# Helper function to count letters only
nchar_nonu <- function(x) {
  if (is.null(x)) return(0)
  sapply(x, function(s) {
    if (is.na(s) || is.null(s)) return(0)
    s_clean <- gsub("[^A-Za-z]", "", s)
    nchar(s_clean)
  })
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# -------- LOOP THROUGH GENES --------

for (taxon in taxa) {
  for (gene in genes) {
    cat(taxon, "\n")
    cat(gene, "\n\n")
    min_length <- gene_min_lengths[[gene]]
    gene_query <- paste0(gene, "[Gene]")
    search_term <- paste(taxon, "[Organism] AND", gene_query)
    
    cat("\n------------------------------\n")
    cat("Searching NCBI with term:\n", search_term, "\n")
    
    # Search NCBI
    search_results <- entrez_search(
      db = "nuccore",
      term = search_term,
      retmax = retmax
    )
    
    cat("Found", search_results$count, "records.\n")
    
    if (length(search_results$ids) == 0) {
      cat("No records found for this gene. Skipping.\n")
      next
    }
    
    # -------- FETCH SUMMARIES AND FILTER BY LENGTH --------
    
    filtered_ids <- c()
    summary_list <- list()
    
    num_batches <- ceiling(length(search_results$ids) / batch_size)
    
    pb <- txtProgressBar(min = 0, max = num_batches, style = 3)
    
    for (b in seq_len(num_batches)) {
      i <- (b - 1) * batch_size + 1
      batch_ids <- search_results$ids[i:min(i+batch_size-1, length(search_results$ids))]
      
      summaries <- entrez_summary(db = "nuccore", id = batch_ids)
      
      if (is.null(summaries) || length(summaries) == 0) {
        cat("No summaries returned for this batch. Skipping batch.\n")
        next
      }
      
      for (j in seq_along(summaries)) {
        sumj <- summaries[[j]]
        
        if (is.null(sumj) || length(sumj) == 0) {
          next
        }
        
        seqlen <- sumj$slen
        
        if (!is.null(seqlen) && seqlen >= min_length && seqlen <= max_length) {
          
          uid         <- if (!is.null(sumj$uid)) sumj$uid else NA
          caption     <- if (!is.null(sumj$caption)) sumj$caption else NA
          title       <- if (!is.null(sumj$title)) sumj$title else NA
          length      <- if (!is.null(sumj$slen)) sumj$slen else NA
          createdate  <- if (!is.null(sumj$createdate)) sumj$createdate else NA
          updatedate  <- if (!is.null(sumj$updatedate)) sumj$updatedate else NA
          organism    <- if (!is.null(sumj$organism)) sumj$organism else NA
          taxname     <- if (!is.null(sumj$taxname)) sumj$taxname else NA
          subname     <- if (!is.null(sumj$subname)) paste(unlist(sumj$subname), collapse="; ") else NA
          biomol      <- if (!is.null(sumj$biomol)) sumj$biomol else NA
          moltype     <- if (!is.null(sumj$moltype)) sumj$moltype else NA
          extra       <- if (!is.null(sumj$extra)) sumj$extra else NA
          
          summary_row <- data.frame(
            uid = uid,
            accession = caption,
            title = title,
            length = length,
            createdate = createdate,
            updatedate = updatedate,
            organism = organism,
            taxname = taxname,
            subname = subname,
            biomol = biomol,
            moltype = moltype,
            extra = extra,
            stringsAsFactors = FALSE
          )
          
          summary_list[[length(summary_list) + 1]] <- summary_row
          filtered_ids <- c(filtered_ids, uid)
        }
      }
      
      setTxtProgressBar(pb, b)
      Sys.sleep(sleep_time)
    }
    
    close(pb)
    
    cat("\nNumber of sequences within length filter:", length(filtered_ids), "\n")
    
    if (length(filtered_ids) == 0) {
      cat("No sequences found within length range for this gene. Skipping.\n")
      next
    }
    
    # -------- SAVE CSV OF SUMMARY DATA --------
    
    if (length(summary_list) > 0) {
      summary_df <- do.call(rbind, summary_list)
      
      csv_outfile <- file.path(output_dir, paste0(
        gsub(" ", "_", taxon), "_",
        gene,
        "_", "NCBI", "_", min_length, "-", max_length, "bp_", timestamp, ".csv"
      ))
      
      write.csv(summary_df, csv_outfile, row.names = FALSE)
      cat("CSV summary saved to:", csv_outfile, "\n")
    } else {
      cat("No summary data to write for this gene.\n")
      next
    }
    
    # -------- FETCH SEQUENCES IN BATCHES --------
    
    all_seqs <- character()
    
    num_batches_fetch <- ceiling(length(filtered_ids) / batch_size)
    pb2 <- txtProgressBar(min = 0, max = num_batches_fetch, style = 3)
    
    for (b in seq_len(num_batches_fetch)) {
      i <- (b - 1) * batch_size + 1
      batch_ids <- filtered_ids[i:min(i+batch_size-1, length(filtered_ids))]
      
      cat(sprintf("\nFetching batch %d of %d ...\n", b, num_batches_fetch))
      
      seqs_batch <- entrez_fetch(
        db = "nuccore",
        id = batch_ids,
        rettype = "fasta",
        retmode = "text"
      )
      
      all_seqs <- c(all_seqs, seqs_batch)
      setTxtProgressBar(pb2, b)
      Sys.sleep(sleep_time)
    }
    
    close(pb2)
    
    if (length(all_seqs) == 0) {
      cat("No sequences fetched for this gene. Skipping writing to FASTA.\n")
      next
    }
    
    # -------- CLEAN NCBI FASTA TO SINGLE-LINE WITH CLEAN HEADER --------
    
    combined_fasta_text <- paste(all_seqs, collapse = "")
    records <- unlist(strsplit(combined_fasta_text, "(?=>)", perl = TRUE))
    
    # Remove empty strings
    records <- records[nzchar(records)]
    
    records_singleline <- lapply(records, function(rec) {
      lines <- unlist(strsplit(rec, "\n"))
      
      if (length(lines) < 2) {
        return(NULL)
      }
      
      header_full <- lines[1]
      
      # Clean header safely
      header_clean <- gsub("^>", "", header_full)
      
      if (nchar(header_clean) > 0) {
        acc_raw <- strsplit(header_clean, "\\s+")[[1]][1]
        acc_clean <- gsub("\\.\\d+$", "", acc_raw)
      } else {
        acc_clean <- "UNKNOWN"
      }
      
      seq <- paste(lines[-1], collapse = "")
      seq <- gsub("\\s", "", seq)
      
      if (nchar(seq) == 0) {
        return(NULL)
      }
      
      paste0(">", acc_clean, "\n", seq)
    })
    
    # Remove NULLs
    records_singleline <- records_singleline[!sapply(records_singleline, is.null)]
    
    if (length(records_singleline) == 0) {
      cat("No valid FASTA records found after cleaning. Skipping FASTA writing.\n")
      next
    }
    
    records_singleline <- as.character(records_singleline)
    
    # -------- WRITE CLEANED FASTA --------
    
    fasta_outfile <- file.path(output_dir, paste0(
      gsub(" ", "_", taxon), "_",
      gene,
      "_", "NCBI", "_", min_length, "-", max_length, "bp_", timestamp, ".fasta"
    ))
    
    writeLines(records_singleline, fasta_outfile)
    
    cat("\nNCBI sequences saved to single-line FASTA:", fasta_outfile, "\n")
    
    
    cat("\n******************************\n")
    
    cat("Starting BOLD access...\n")
    
    if (gene == "COI") {
      cat("\n------------------------------\n")
      cat("Querying BOLD Systems for taxon:", taxon, "\n")
      
      bold_url <- paste0(
        "https://www.boldsystems.org/index.php/API_Public/combined?",
        "taxon=", URLencode(taxon)
      )
      
      temp_file <- tempfile(fileext = ".xml")
      download.file(bold_url, temp_file, quiet = TRUE)
      
      bold_lines <- readLines(temp_file, warn = FALSE)
      
      if (length(bold_lines) == 0 ||
          any(grepl("<!DOCTYPE|<html|No records found", bold_lines, ignore.case = TRUE))) {
        cat("BOLD returned HTML or no records. Skipping.\n")
        next
      }
      
      xml_doc <- read_xml(temp_file)
      records <- xml_find_all(xml_doc, ".//record")
      
      if (length(records) == 0) {
        cat("No records found in BOLD XML.\n")
        next
      }
      
      processid <- xml_text(xml_find_all(records, ".//processid"))
      sequence <- xml_text(xml_find_all(records, ".//nucleotides"))
      taxonomy <- xml_text(xml_find_all(records, ".//taxonomy"))
      
      valid_idx <- which(sequence != "" & !is.na(sequence))
      processid <- processid[valid_idx]
      sequence <- sequence[valid_idx]
      taxonomy <- taxonomy[valid_idx]
      
      if (length(sequence) == 0) {
        cat("No usable sequences in BOLD XML. Skipping.\n")
        next
      }
      
      bold_df <- data.frame(
        accession = processid,
        taxonomy = taxonomy,
        sequence = sequence,
        stringsAsFactors = FALSE
      )
      
      bold_df$seq_length <- sapply(bold_df$sequence, function(s) {
        nchar(gsub("[^A-Za-z]", "", s))
      })
      
      bold_df_filtered <- subset(
        bold_df,
        seq_length >= min_length &
          seq_length <= max_length
      )
      
      cat("BOLD records fetched:", nrow(bold_df), "\n")
      cat("BOLD records after length filtering:", nrow(bold_df_filtered), "\n")
      
      if (nrow(bold_df_filtered) > 0) {
        csv_outfile_bold <- file.path(output_dir, paste0(
          gsub(" ", "_", taxon), "_",
          "COI",
          "_BOLD_", min_length, "-", max_length, "bp_", timestamp, ".csv"
        ))
        write.csv(bold_df_filtered, csv_outfile_bold, row.names = FALSE)
        cat("BOLD CSV saved to:", csv_outfile_bold, "\n")
        
        fasta_outfile_bold <- file.path(output_dir, paste0(
          gsub(" ", "_", taxon), "_",
          "COI",
          "_BOLD_", min_length, "-", max_length, "bp_", timestamp, ".fasta"
        ))
        
        fasta_seqs <- paste0(
          ">", bold_df_filtered$accession,
          "\n",
          bold_df_filtered$sequence
        )
        writeLines(fasta_seqs, fasta_outfile_bold)
        cat("BOLD FASTA saved to:", fasta_outfile_bold, "\n")
        
      } else {
        cat("No BOLD sequences passed length filter.\n")
      }
    }
    cat("***********\n")
  }
  cat("***********\n")
}

cat("\nAll done!\n")
