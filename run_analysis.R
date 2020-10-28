#Getting and Cleaning Data

#Load the packages and get the data
packages <- c("data.table", "reshape2")
sapply(packages, require, character.only = TRUE, quietly = TRUE)
path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")

#Load labels and measurements
labels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt"), 
                col.names = c("classLabels", "activityName"))
feat <- fread(file.path(path, "UCI HAR Dataset/features.txt"), 
              col.names = c("index", "featureNames"))
feat1 <- grep("(mean|std)", feat[, featureNames])
measurements <- feat[feat1, featureNames]
measurements <- gsub('[()]', '', measurements)

#Load train dataset
train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, feat1, with = FALSE]
data.table::setnames(train, colnames(train), measurements)
trainActivities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt"), 
                         col.names = c("Activity"))
trainSubjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt"), 
                       col.names = c("SubjectNum"))
train <- cbind(trainSubjects, trainActivities, train)

#Load test dataset
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, feat1, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
testActivities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt"), 
                        col.names = c("Activity"))
testSubjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt"), 
                      col.names = c("SubjectNum"))
test <- cbind(testSubjects, testActivities, test)

#Combine train and test datasets; fill in the labels
comb <- rbind(train, test, fill=TRUE)

#Create independent tidy dataset
comb[["Activity"]] <- factor(comb[, Activity]
                             , levels = activityLabels[["classLabels"]]
                             , labels = activityLabels[["activityName"]])
comb[["SubjectNum"]] <- as.factor(comb[, SubjectNum])
comb <- reshape2::melt(data = comb, id = c("SubjectNum", "Activity"))
comb <- reshape2::dcast(data = comb, 
                        SubjectNum + Activity ~ variable, fun.aggregate = mean)
data.table::fwrite(x = comb, file = "tidyData.csv", quote = FALSE)

