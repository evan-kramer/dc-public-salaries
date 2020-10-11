# -*- coding: utf-8 -*-
'''
Evan Kramer
10/10/2020
'''
# Set up
import os
os.chdir('U:/dc_public_salaries')
from urllib.request import urlopen, Request 
import requests
from bs4 import BeautifulSoup
import tabula
import re
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from datetime import datetime

# Get html structure
hdrs = {'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'}
html = urlopen(Request('https://dchr.dc.gov/public-employee-salary-information', headers = hdrs))
bs = BeautifulSoup(html.read(), "lxml")

# Find salary files
for i in bs.findAll('a'):
    if '.pdf' in str(i) and 'employee' in str(i):
        # Extract url
        url = re.search('<a href="(.*?)"', str(i)).group(1)
        filename = re.search('attachments/(.*?).*$', str(i)).group(1)
        # Download file
        print(url)
        print(filename)
        # temp = tabula.read_pdf(urlopen(Request(url, headers = hdrs)), pages = 'all')
        # https://medium.com/better-programming/convert-tables-from-pdfs-to-pandas-with-python-d74f8ac31dc2
    else:
        pass
    
temp = tabula.read_pdf('Raw Salary Files/public_body_employee_information_0314.pdf',
                       pages = 'all')

# Scrape/download salary files