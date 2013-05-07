# first script in compiling data for savvy map
# from data.medicare.gov Hospital Compare csv files

# read in necessary data files
ooc <- read.csv(file="Outcome of Care Measures.csv", header=T, sep=",", quote="\"", colClasses=c(
	"ZIP.Code"="character"))
#	"Hospital.30.Day.Death..Mortality..Rates.from.Heart.Attack"="numeric",
#	"Hospital.30.Day.Death..Mortality..Rates.from.Heart.Failure"="numeric",
#	"Hospital.30.Day.Death..Mortality..Rates.from.Pneumonia"="numeric",
#	"Hospital.30.Day.Readmission.Rates.from.Heart.Attack"="numeric",
#	"Hospital.30.Day.Readmission.Rates.from.Heart.Failure"="numeric",
#	"Hospital.30.Day.Readmission.Rates.from.Pneumonia"="numeric"))
ooc_nat <- read.csv(file="Outcome of Care Measures - National.csv", header=T, sep=",")
hac_nat <- read.csv(file="Hospital Acquired Condition - National.csv", header=T, sep=",")
hac <- read.csv(file="Hospital Acquired Condition.csv", header=T, sep=",")
pocm_ha <- read.csv(file="Process of Care Measures - Heart Attack.csv", header=T, sep=",")
hcaphs <- read.csv(file="HCAHPS Measures.csv", header=T, sep=",")
ha <- read.csv(file="hai-knee-infection_heart_attack.csv", sep="\t", header=T, na.strings=c("na", "sample size too small to report"))


# convert rate column to numeric
hac$Rate..per.1.000.Discharges. <- as.numeric(levels(hac$Rate..per.1.000.Discharges.))[hac$Rate..per.1.000.Discharges.]

# subset to just MA
ooc <- ooc[ooc$State=="MA", ]

# colums to extract from ooc
oocCols <- c("Provider.Number", "Hospital.Name", "Address.1", "City", "State", "ZIP.Code", "Hospital.30.Day.Death..Mortality..Rates.from.Heart.Failure", "Hospital.30.Day.Readmission.Rates.from.Pneumonia", "Hospital.30.Day.Death..Mortality..Rates.from.Heart.Attack", "Hospital.30.Day.Death..Mortality..Rates.from.Pneumonia", "Hospital.30.Day.Readmission.Rates.from.Heart.Attack", "Hospital.30.Day.Readmission.Rates.from.Heart.Failure"
)

# subset to only desired columns
ooc <- ooc[, names(ooc) %in% oocCols]

# rename columns to something sensible
names(ooc) <- c("id", "name", "address", "city", "state", "zip", "heart.fail.30.day.mort", "pneum.30.day.readm", "heart.attack.30.day.mort", "pneum.30.day.mort", "heart.attack.30.day.readm",
"heart.fail.30.day.readm")
names(ha) <- c("name", "address", "KPRO Infections", "KPRO Procedures", "heart attack recom care", "heart fail recom care", "pneum recom care", "leapfrog")

# merge address fields (will need this so google maps can geocode correctly)
ooc$address <- paste(ooc$address, ooc$city, ooc$state, ooc$zip)

# subset to same set of hospitals as ooc
hac <- hac[hac$Provider.ID %in% ooc$id, ]
pocm_ha <- pocm_ha[pocm_ha$Provider.Number %in% ooc$id, ]
hcaphs <- hcaphs[hcaphs$Provider.Number %in% ooc$id, ]

# select only desired columns
hacCols <- c("Provider.ID", "Measure", "Rate..per.1.000.Discharges.")
hac <- hac[, names(hac) %in% hacCols]
pocm_haCols <- names(pocm_ha)[!(names(pocm_ha) %in% c("Hospital.Name", "Address.1", "Address.2", "Address.3", "City", "State", "ZIP.Code", "County.Name", "Phone.Number"))]
pocm_ha <- pocm_ha[, names(pocm_ha) %in% pocm_haCols]
hcaphsCols <- names(hcaphs)[!(names(hcaphs) %in% c("Hospital.Name", "Address.1", "Address.2", "Address.3", "City", "State", "ZIP.Code", "County.Name", "Phone.Number"))]
hcaphs <- hcaphs[, names(hcaphs) %in% hcaphsCols]

# name columns something sensible
names(hac) <- c("id", "measure", "rate.per.1k.disch")
names(pocm_ha)[1] <- "id"
names(hcaphs)[1] <- "id"

# convert hac measure data to columns
tmp <- data.frame()
for (i in levels(as.factor(hac$id))) {
    r <- hac[hac$id==i, ]$rate.per.1k.disch
    r <- data.frame(matrix(r, nrow=1))
    r$id <- i
    print(r)
    names(r) <- c(as.character(hac[hac$id==i, ]$measure), "id")
    print(r)
    tmp <- rbind(tmp, r)
}

# assemble final data frame for output
final <- merge(ooc, tmp, by="id")
final <- merge(final, pocm_ha, by="id")
final <- merge(final, hcaphs, by="id")
final <- merge(final, ha[, names(ha)!="address"], by="name")

# columns to be output from final df
finalCols <- c("name", "address", names(ooc)[7:length(names(ooc))], names(tmp)[2:length(names(tmp))], names(pocm_ha)[2:length(names(pocm_ha))], names(hcaphs)[2:length(names(hcaphs))], names(ha)[3:length(names(ha))])
final <- final[, names(final) %in% finalCols]

# columns for which to calculate state avgs
avg_cols <- c("heart fail recom care", "heart.fail.30.day.mort", "heart.fail.30.day.readm",
			  "heart attack recom care", "heart.attack.30.day.mort", "heart.attack.30.day.readm", 
			  "pneum recom care", "pneum.30.day.mort", "pneum.30.day.readm",
			  "KPRO Infections", "KPRO Procedures", "Falls and injuries")
# calculate state avgs
for (x in avg_cols) {
	final[, paste(x, "state_avg", sep=".")] <- mean(final[, x], na.rm=T)
}

# add national averages from ooc_nat & hac_nat
for (x in levels(as.factor(ooc_nat[, "Measure.Name"]))) {
	final[, paste(x, "National")] <- ooc_nat[ooc_nat$Measure.Name==x, "National.Mortality.Readmission.Rate"]
}
final[, "Falls and injuries National"] <- hac_nat[hac_nat$Measure=="Falls and injuries", ]$Score

# clean up column names
names(final) <- gsub("\\.", " ", names(final))

# write output
write.table(final, file="savvyData.txt", col.names=T, row.names=F, sep="\t", quote=F, eol="\n")
