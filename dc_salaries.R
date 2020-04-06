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
library(readxl)
setwd("U:/dc_public_salaries")

# Scrape from webpage?
# Extract file urls
url = read_html("https://dchr.dc.gov/public-employee-salary-information")
salary_files = tibble(
  link = as.character(html_nodes(url, "a")),
  link_start = str_locate(link, "https"),
  link_end = str_locate(link, ".pdf") + 3,
  # file_date_start = str_locate(link, '">Public Body Employee Information as of'),
  file_date_start = str_locate(link, '">'),
  file_url = NA,
  file_name = NA,
  file_date = NA
) %>% 
  filter(str_detect(str_to_lower(link), "as of")) 
for(r in 1:nrow(salary_files)) {
  salary_files$file_url[r] = str_sub(salary_files$link[r], 
                                     salary_files$link_start[r],
                                     salary_files$link_end[r])
  salary_files$file_name[r] = str_replace(
    salary_files$file_url[r], 
    "https://dchr.dc.gov/sites/default/files/dc/sites/dchr/publication/attachments/",
    ""
  )
  salary_files$file_date[r] = str_sub(salary_files$link[r],
                                      salary_files$file_date_start,
                                      str_length(salary_files$link[r]) - 3)
}

# Scrape leadership from web
lt = read_html("https://osse.dc.gov/page/meet-leadership-team")
lt_names = tibble(
  link = as.character(html_nodes(lt, "a")),
  lt_name_start = NA,
  lt_name_end = NA,
  lt_name = NA
) %>% 
  filter(str_detect(link, "email-protection"))
for(r in 1:nrow(lt_names)) {
  lt_names$lt_name_start[r] = str_locate(lt_names$link[r], ">")[2] + 1
  lt_names$lt_name_end[r] = str_locate(lt_names$link[r], "</a>")[1] - 1
  # lt_names$lt_name = str_sub(lt_names$link[r], lt_names$lt_name_start[r], lt_names$lt_name_end[r])
}
lt_names = mutate(lt_names, lt_name = str_sub(link, lt_name_start, lt_name_end)) %>% 
  filter(!str_detect(lt_name, ">")) %>% 
  transmute(full_name = lt_name) %>% 
  separate(full_name, sep = " ", into = c("first_name", "last_name", "overflow"), remove = F) %>% 
  transmute(
    full_name,
    first_name = ifelse(is.na(overflow), first_name, str_c(first_name, " ", last_name)),
    last_name = ifelse(is.na(overflow), last_name, overflow)
  )

# Download files from internet
for(f in 1:nrow(salary_files)) {
  # Check if the file exists then download
  if(!file.exists(str_c(getwd(), "/Raw Salary Files/", salary_files$file_name[f]))) {
    download.file(
      url = salary_files$file_url[f],
      mode = "wb",
      destfile = str_c(
        getwd(), "/Raw Salary Files/", salary_files$file_name[f]
      ),
      quiet = T
    )
  }
}
rm(f)

# Extract information using `pdf_text`
temp = pdf_text(
  pdf = str_c(getwd(), "/Raw Salary Files/", list.files(str_c(getwd(), "/Raw Salary Files/"))[1])
)

test = tibble(
  text = unlist(str_split(temp[1], "\r\n"))
) %>% 
  separate(text, into = str_c("v_", 1:100), sep = " ") %>% 
  mutate_all("str_trim") %>% 
  mutate_all("str_to_upper") %>% 
  mutate_at(
    vars(starts_with("v_")),
    funs(ifelse(. == "", NA_character_, .))
  ) %>% 
  unite(col = "text2", starts_with("v_"), na.rm = T, sep = " ") %>% 
  mutate(
    appt_end = NA,
    appt = NA, 
    last_name = NA,
    first_name = NA,
    title = NA,
    salary = NA,
    hire_date = NA,
    next_space = NA
  )

test$text2[r]
test["appt"] %>% unlist() %>% .[3]

for(r in 1:nrow(test)) {
  # Appointment
  test$appt_end[r] = min(str_locate(test$text2[r], "APP"), na.rm = T)
  test$appt[r] = str_sub(test$text2[r], 1, test$appt_end[r] + 3)
  test$text2[r] = str_replace(
    test$text2[r],
    unlist(test["appt"])[r],
    ""
  ) %>% 
    str_trim()
    
  # Loop through the rest
  for(v in c("last_name", "first_name", "title", "salary", "hire_date")) {
    # test$text2[r] = str_trim(str_replace_all(test$text2[r], test[, v][r,], ""))
    test$next_space[r] = min(str_locate(str_trim(test$text2[r]), " "), na.rm = T)
    test[, v][r,] = str_sub(test$text2[r], 1, test$next_space[r])
    test$text2[r] = str_replace(
      test$text2[r],
      unlist(test[v])[r],
      ""
    ) %>% 
      str_trim()
  }
}

# We'll have to get creative around using the numbers from salaries/hire dates to pull 
# titles of different lengths apart
# And what about adding dates? 