# DC Salaries
# Evan Kramer

# Set up
options(java.parameters = "-Xmx16G")
library(tidyverse)
library(lubridate)
library(haven)
library(httr)
library(rvest)
library(pdftools)
setwd("C:/Users/evan.kramer/Documents/dc_public_salaries")

# Scrape from webpage?
# Extract file urls
url = read_html("https://dchr.dc.gov/public-employee-salary-information")
salary_files = tibble(
  link = as.character(html_nodes(url, "a")),
  link_start = str_locate(link, "https"),
  link_end = str_locate(link, ".pdf") + 3,
  file_url = NA
) %>% 
  filter(str_detect(str_to_lower(link), "as of")) 
for(r in 1:nrow(salary_files)) {
  salary_files$file_url[r] = str_sub(salary_files$link[r], 
                                     salary_files$link_start[r],
                                     salary_files$link_end[r])
}

# Download all PDFs -- Is there a way to read tables directly from URLs? 
walk2(
  .x = salary_files$file_url, 
  .y = salary_files$file_url,
  .f = download.filemode = "wb"
)



download.file(
  url = salary_files$file_url[1], 
  destfile = str_c(getwd(), "/", str_sub(salary_files$file_url[1], -15, -1))
)



# Get data from file urls
for(f in salary_files$file_url) {
  
}


# Load file from internet
dc = readxl::read_excel(
  path = "C:/Users/CA19130/Downloads/public_body_employee_information_123118.xlsx",
  # path = "C:/Users/CA19130/Downloads/public_body_employee_information_03312019.xlsx",
  # path = "C:/Users/CA19130/Downloads/public_body_employee_information_06302019.xlsx",
  col_names = F,
  skip = 1
)
  



# Check to see which variables contain all missing data
y = c()
for(v in 1:ncol(dc)) {
  w = dc[, str_c("...", v)]
  x = sum(!is.na(w))
  if(x == 0) {
    print(str_c("...", v)); print(x)
    y = c(y, str_c("...", v))
  }
}
# Remove variables with all missing data
for(v in y) {
  dc[, v] = NULL
}
rm(y, v, w, x)

# How many nonmissing variables are there? Can we select only if character or datetime?
dim(dc)

# Create new variables
dc = transmute(
  dc, 
  agency_name = `...1`, 
  last_name = str_c(ifelse(is.na(`...3`), "", `...3`), 
                    ifelse(is.na(`...5`), "", `...5`), 
                    ifelse(is.na(`...6`), "", `...6`)),
  first_name = str_c(ifelse(is.na(`...10`), "", `...10`),
                     ifelse(is.na(`...13`), "", `...13`)),
  type_appt = str_c(ifelse(is.na(`...14`), "", `...14`),
                    ifelse(is.na(`...19`), "", `...19`)),
  position_title = str_c(ifelse(is.na(`...20`), "", `...20`),
                         ifelse(is.na(`...21`), "", `...21`)),
  grade = str_c(ifelse(is.na(`...23`), "", `...23`),
                ifelse(is.na(`...25`), "", `...25`)),
  compensation = as.numeric(str_c(ifelse(is.na(`...26`), "", `...26`),
                                  ifelse(is.na(`...28`), "", `...28`))),
  hire_date = `...29`
) 

# Leadership team salaries
first = c(
  "lida", "darrell", "gretchen", "thomas", "sarah jane", "shavonne",
  "elizabeth", "sarah", "sara", "antoinette", "elisabeth", "heidi",
  "pete", "shana", "william", "hanseul", "don", "jason"
)
last = c(
  "alikhani", "ashton", "brumley", "fontenot", "forman", "gibson", 
  "groginsky", "martin", "meyers", "mitchell", "morse", "schumacher",
  "siu", "young", "henderson", "kang", "davis", "kim"
)
lteam = tibble()
for(n in 1:length(first)) {
  lteam = filter(dc, str_to_upper(last_name) == str_to_upper(last[n]) & 
                  str_to_upper(first_name) == str_to_upper(first[n])) %>% 
    bind_rows(lteam, .) %>% 
    arrange(last_name)
}

# 130000, 175286, 176794, 173000, 157380, 161160, 170000, 126072, 180544,
# 160766, 168000, 145438, 172597

# What is the typical salary for directors
filter(
  dc, 
  str_to_lower(agency_name) == "ofc. of state superintendent",
  str_detect(str_to_lower(position_title), "director")
) %>% 
  summarize_at(
    vars(compensation),
    c("mean", "min", "max", "sd"),
    na.rm = T
  )
