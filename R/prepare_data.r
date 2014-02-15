parsePeakFile <- function(file, start_column = 2, end_column = 0, score_column = 0) {
  peaks <- read.table(file, sep = "\t", header = FALSE)
  # detect header line if it exists
  if (is.factor(peaks[, start_column])) { 
    peaks <- read.table(file, sep = "\t", header = TRUE)
  }

  genomicdata <- data.frame(as.factor(peaks[, 1]), peaks[, start_column])

  if (end_column && !score_column) { 
    genomicdata <- cbind(genomicdata, peaks[, end_column] - peaks[, start_column]) 
  } else if (!end_column && score_column) {
    genomicdata <- cbind(genomicdata, peaks[, score_column])
  } else if (end_column && score_column) {
    genomicdata <- cbind(genomicdata, 
                  (peaks[, end_column] - peaks[, start_column]) * peaks[, score_column])
  } else {
    genomicdata <- cbind(genomicdata, rep(1, nrow(genomicdata)))
  }

  names(genomicdata) <- c("Chromosome", "loc", "size")
  return(genomicdata)
}

checkSpecies <- function(genomicdata) {
  if ("chr20" %in% genomicdata$Chromosome | 
      "chr21" %in% genomicdata$Chromosome | 
      "chr22" %in% genomicdata$Chromosome) {
    return("human")
  } else if ("chr19" %in% genomicdata$Chromosome | 
             "chr18" %in% genomicdata$Chromosome | 
             "chr17" %in% genomicdata$Chromosome) {
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


fetchCentromeres <- function(species) {
  if (species == "human") {
    centromeres <- read.table("./Data/HumanCentromerePositions.txt", sep = "\t")
  } else {
    #all mouse chromosomes are telocentric, so it's pointless to plot the centromeres.
    centromeres <- data.frame("chr1", 0, 0) 
  }
  names(centromeres) <- c("Chromosome", "start", "end")
  return(centromeres)
}