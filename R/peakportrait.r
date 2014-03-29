library(ggplot2)
library(gtools) # for reordering chromosome names
source("./R/prepare_data.r")   
errors <- as.integer(0)

tryCatch({
  gdata <- parsePeakFile(file, start_column, end_column, score_column)
}, error = function(e) errors <<- "Failed to parse file. It must be tab-delimited text.")

# if there are too many chromosome names, ggplot2 will get stuck 
# when it tries to graph them. need to return an error instead.
if((nlevels(gdata$Chromosome) > 50) && errors == 0) errors <<- "It looks like the file has more than 50 different chromosome names. Verify that column 1 contains chromosome names in a consistent format like: 'chr1', 'chr2'."

if(errors == 0) tryCatch({
  if(species == "Auto-detect") species <- checkSpecies(gdata)
  gdata <- rbind(gdata, fetchChromosomeLengths(species))
  centromeres <- fetchCentromeres(species)
  gdata$Chromosome <- factor(gdata$Chromosome, mixedsort(levels(gdata$Chromosome)))
  }, error = function(e) errors <<- "Failed to set axis limits for the selected species. Try using species = other.")

if(errors == 0) try({
  theme_set(theme_gray(base_size = 18)) # make fonts bigger
  png("./tmp/graph.png", type="cairo-png", width = 900, height=600)
    hist_results <- ggplot(gdata, aes(x = loc/1000000, weight = size))
    hist_results <- hist_results + geom_freqpoly(size = 1.2) + 
      xlab("Position along chromosome (Mbp)") + ylab("Intensity") 
    if (species == "human") { hist_results <- hist_results + geom_vline(aes(xintercept = start/1000000), data = centromeres) }

    hist_results <- hist_results + facet_wrap(~ Chromosome, drop = FALSE, scales = "free_x")
    print(hist_results)
  dev.off()
  })