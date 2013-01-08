'''
a script for pulling data from data.medicare.gov

@author: Ted Natoli
@email: ted.e.natoli@gmail.com
'''

import urllib2
import json

HOA_URL = 'http://data.medicare.gov/api/views/f24z-mvb9/rows.json'
HAC_URL = 'http://data.medicare.gov/api/views/qd2y-qcgs/rows.json'

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

if __name__ == '__main__':
	url = urllib2.urlopen(HAC_URL)
	j = json.load(url)
	data = j['data']
	# types of data include int, list, None, unicode
	# looks like each table entry is stored as a list
	ma = subsetToState(data, 'MA', 14)
	for m in ma:
		print m[14]