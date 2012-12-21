'''
a script for pulling data from data.medicare.gov

@author: Ted Natoli
@email: ted.e.natoli@gmail.com
'''

import urllib2
import json

HOA_URL = 'http://data.medicare.gov/api/views/f24z-mvb9/rows.json'

if __name__ == '__main__':
	url = urllib2.urlopen(HOA_URL)
	j = json.load(url)
	data = j['data']
	# types of data include int, list, None, unicode
	for d in data:
		for l in d:
			if isinstance(l, unicode):
				print l