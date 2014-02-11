parsePeakFile <- function(file, start_column = 2, end_column = 0, score_column = 0) {
  peaks <- read.table(file, sep = "\t", header = FALSE)
  # detect header line if it exists
  if (is.factor(peaks[, start_column])) { 
    peaks <- read.table(file, sep = "\t", header = TRUE)
  }

  data <- data.frame(as.factor(peaks[, 1]), peaks[, start_column])

  if (end_column && !score_column) { 
    data <- cbind(data, peaks[, end_column] - peaks[, start_column]) 
  } else if (!end_column && score_column) {
    data <- cbind(data, peaks[, score_column])
  } else if (end_column && score_column) {
    data <- cbind(data, 
                  (peaks[, end_column] - peaks[, start_column]) * peaks[, score_column])
  } else {
    data <- cbind(data, rep(1, nrow(data)))
  }

  names(data) <- c("Chromosome", "loc", "size")
  return(data)
}

checkSpecies <- function(data) {
  if ("chr20" %in% data$Chromosome | 
      "chr21" %in% data$Chromosome | 
      "chr22" %in% data$Chromosome) {
    return("human")
  } else if ("chr19" %in% data$Chromosome | 
             "chr18" %in% data$Chromosome | 
             "chr17" %in% data$Chromosome) {
    return("mouse")
  } else {
    return("unknown")
  }
}

fetchChromosomeLengths <- function(species) {
  if (species == "human") {
    return(read.table("./data/HumanChromosomeLengths.txt", sep = "\t", header = TRUE))
  } else if (species == "mouse") {
    return(read.table("./data/MouseChromosomeLengths.txt", sep = "\t", header = TRUE))
  } else {
    return()
  }
}
