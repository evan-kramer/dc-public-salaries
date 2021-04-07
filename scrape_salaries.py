# -*- coding: utf-8 -*-
'''
Evan Kramer
4/7/2021
'''
# https://medium.com/better-programming/convert-tables-from-pdfs-to-pandas-with-python-d74f8ac31dc2
# https://stackabuse.com/download-files-with-python/
# Set up
import os
from urllib.request import urlopen, Request
import requests
from bs4 import BeautifulSoup
import tabula
import re
import pandas as pd
# import matplotlib.pyplot as plt
# import numpy as np
# from datetime import datetime

# Get html structure
hdrs = {'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'}
html = urlopen(Request('https://dchr.dc.gov/public-employee-salary-information', headers = hdrs))
bs = BeautifulSoup(html.read(), "lxml")

# Check if files are already there
os.chdir('U:/dc_public_salaries/Raw Salary Files/')
file_list = pd.DataFrame({'file': os.listdir(),
                          'file_date': [''] * len(os.listdir())})

# Find salary files
for i in bs.findAll('a'):
    if '.pdf' in str(i) and 'employee' in str(i):
        # Extract url and file date
        url = re.search('<a href="(.*?)"', str(i)).group(1)
        filename = re.search('attachments/(.*?)$', url).group(1)
        filedate = re.search('as of (.*?)</a>', str(i)).group(1)
        file_list.file_date[file_list.file == filename] = filedate
        # Check whether file is already downloaded
        if filename not in list(file_list.file):
            # Download file
            r = requests.get(url, headers = hdrs, stream = True)
            # Write file to disk
            try:
                with open('U:/dc_public_salaries/Raw Salary Files/' + filename, 'wb') as f:
                    f.write(r.content)
            except:
                pass
    else:
        pass

# Read from files
for f in os.listdir():
    file = f.replace('.pdf', '.csv')
    if file not in os.listdir():
        try:
            tabula.read_pdf(f, pages = 'all').to_csv(file, index = False)
        except:
            pass
    else:
        pass

# Clean files
file    
    