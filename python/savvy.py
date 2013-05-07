'''
a script for pulling data from data.medicare.gov

@author: Ted Natoli
@email: ted.e.natoli@gmail.com
'''

import urllib2
from BeautifulSoup import BeautifulSoup as bs
import json

HOA_URL = 'http://data.medicare.gov/api/views/f24z-mvb9/rows.json'
HAC_URL = 'http://data.medicare.gov/api/views/qd2y-qcgs/rows.json'
Leapfrog_URL = 'http://www.hospitalsafetyscore.org/search-result.html?zip_code=&hospital=&city=&state_prov=MA&agree=agree&orderby=score&orderby=name'

def subsetToState(data_lists, state, ind):
	'''
	subset data_lists to include only state by
	looking at element given by ind
	'''
	subset = []
	for d in data_lists:
		if d[14] == state:
			subset.append(d)
	return subset

def getLeapfrogData(url):
	'''
	get patient safety grade from leapfrog website
	'''
	# prevent cookies and redirects from interfering
	#opener = urllib2.build_opener(urllib2.HTTPCookieProcessor())
	#response = opener.open(url)
	#html = response.read()
	#soup = bs(html)
	hosp2score = {}
	page = urllib2.urlopen(url)
	soup = bs(page)
	div_tags = soup.findAll('div', attrs={'class':'left-img'})
	for d in div_tags:
		# need to get hospital name somehow
		src = d.img.attrs[0][1]
		img_name = os.path.splitext(os.path.basename(src))[0]
		hosp2score(hosp) = img_name[-1]

if __name__ == '__main__':
	getLeapfrogData(Leapfrog_URL)