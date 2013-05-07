# an attempt at reading directly from json connection

# TODO:
# 1. update to pull direct from leapfrog, knee infections
# 2. automate geocoding if possible

# check for required packages
if (!library("rjson", logical.return=T)) {
	install.packages("rjson")
}
require("rjson")

urls <- c(OOC_URL = "http://data.medicare.gov/api/views/f24z-mvb9/rows.json",
		  HAC_URL = "http://data.medicare.gov/api/views/qd2y-qcgs/rows.json",
		  POC_URL = "http://data.medicare.gov/api/views/nymf-dpgw/rows.json",
		  OOC_NAT_URL = "http://data.medicare.gov/api/views/i2h8-79qx/rows.json")

merge_cols <-  c("hospital_name", "address_1", "address_2", "address_3",
				"city", "state", "zip_code")

json2df <- function(url, ind) {
	# convert json object (list of lists)
	# into a data frame
	# use only json_data[[ind]]

	json_data <- fromJSON(file=url)
	# creates a nested list structure
	# annotations in json_data[[1]]
	# all data is stored in json_data[[2]]
	df <- data.frame(t(sapply(json_data[[ind]], as.character)))
	names(df) <- getColNames(json_data)
	return(df)
}

getColNames <- function(json_data, ncols=NULL) {
	col_annots <- json_data[[1]][[1]]$columns
	col_names <- c()
	for (i in 1:length(col_annots)) {
		col_names[length(col_names) + 1] <- col_annots[[i]]$fieldName
	}
	if (!is.null(ncols)) {
		return(col_names[(length(col_names) - ncols + 1):length(col_names)])
	}
	else {
		return(col_names)
	}
}

addFullAddress <- function(df) {
	address_cols <- c("address_1", "address_2", "address_3", "city", "state", "zip_code")
	df$full_address <- paste(df$address_1, df$address_2, df$address_3, df$city, df$state, df$zip_code)
	df$full_address <- gsub("NULL", "", df$full_address)
	return(df)
}

factor2col <- function(df, factor_col, data_col, id_cols) {
	factors <- levels(as.factor(df[, factor_col]))
	df[, data_col] <- unfactor(df[, data_col])
	tmp <- df[df[, factor_col]==factors[1], ]
	tmp[factors[1]] <- tmp[, data_col]
	print(names(tmp))
	for (l in factors[2:length(factors)]) {
		# want a single column of data and identifiers
		col <- df[df[, factor_col]==l, c(id_cols, data_col)]
		names(col)[ncol(col)] <- l
		# id_col should be the only common column
		tmp <- merge(tmp, col, by=id_cols)
	}
	# remove intial factor and data columns
	return(tmp[, !(names(tmp) %in% c(factor_col, data_col))])
}

unfactor <- function(factors) {
	# From http://psychlab2.ucr.edu/rwiki/index.php/R_Code_Snippets#unfactor
	# Transform a factor back into its factor names
   return(levels(factors)[factors])
}

## MAIN PROGRAM ##

# read in data
df1 <- json2df(urls["HAC_URL"], 2)
df2 <- json2df(urls["OOC_URL"], 2)
df3 <- json2df(urls["POC_URL"], 2)
df4 <- read.csv(file="hai-knee-infection_heart_attack.csv", header=T, sep="\t")
df5 <- read.csv(file="hosp_name_web_lat_long.csv", header=T, sep="\t")
name_df <- read.csv(file="GEOSAVVY-TED120712.csv", header=T, sep="\t")

# adjust factors to columns - takes a LONG time
df1 <- factor2col(df1, "measure", "rate_per_1_000_discharges_", c("hospital_name",
			"address_1", "address_2", "address_3", "city", "state", "zip_code"))


# merge all -  should automatically subset to MA only b/c df4 only contains
# MA hospitals
final <- merge(df1, df2, by=merge_cols, all=T)
final <- merge(final, df3, by=merge_cols, all=T)
final <- merge(final, df4, by.x="hospital_name", by.y="name", all=T)
final <- merge(final, df5, by="hospital_name", all=T)

# add full address
final <- addFullAddress(final)

# explicitly subset to MA
final <- final[final$state=="MA", ]
final[] <- lapply(final, "[", drop=T)