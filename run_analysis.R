library(plyr)

#
# Helper functions
#

fileJoin <- function(...) {
  paste(..., sep="/")
}

downloadToDataDir <- function(url, dest) {
  if(!file.exists(dataDir)) { dir.create(dataDir) }
  download.file(url, dest)
}

extractUciHarFile <- function(filePath) {
  fullFilePath <- fileJoin("UCI HAR Dataset", filePath)
  unz(uciHarZipfile, fullFilePath)
}

uciHarDataFile <- function(name, prefix) {
  filePath <- paste(name, "/", prefix, "_", name, ".txt", sep="")
  extractUciHarFile(filePath)
}

loadUciHarData <- function(name) {
  if (!(name %in% c("train", "test"))){ stop("invalid dataset name") }
  
  data <- read.table(uciHarDataFile(name, "X"), col.names=features)
  labels <- read.table(uciHarDataFile(name, "y"))
  subjects <- read.table(uciHarDataFile(name, "subject"))
  
  data$Activity <- labels[,1]
  data$Subject <- subjects[,1]
  
  # Rearranging columns for better reading
  data[, append(c("Activity", "Subject"), head(colnames(data), 561))]
}

#
# Constants
#

dataDir <- "./data"
outputDir <- fileJoin(dataDir, "output")
outputFile <- fileJoin(outputDir, "uci_har_mean_std_averages.csv")
uciHarUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
uciHarZipfile <- fileJoin(dataDir, "uci_har_dataset.zip")

#
# Downloading and loading data
#

if (!file.exists(uciHarZipfile)) {
  downloadToDataDir(uciHarUrl, uciHarZipfile)
}

activityLabels <- read.table(extractUciHarFile("activity_labels.txt"))[,2]
features <- as.character(read.table(extractUciHarFile("features.txt"))[,2])

testData <- loadUciHarData("test")
trainningData <- loadUciHarData("train")

#
# Manipulating data
#

allData <- merge(testData, trainningData, all=TRUE, sort=FALSE)

meanAndStdCols <- grep("Activity|Subject|\\.mean\\.|\\.std\\.", colnames(allData))
meanAndStdData <- allData[,meanAndStdCols]

meanAndStdAverages <- ddply(meanAndStdData, .(Activity,Subject), colMeans)

# Naming activities
meanAndStdAverages$Activity <- as.factor(meanAndStdAverages$Activity)
levels(meanAndStdAverages$Activity) <- activityLabels

#
# Writing final data to CSV
#

if(!file.exists(outputDir)) { dir.create(outputDir) }
write.csv(meanAndStdAverages, outputFile)
