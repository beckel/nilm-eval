from pylab import *
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# http://matplotlib.org/users/customizing.html

font = {'family' : 'Arial',
        'size'   : 32}
        # 'weight' : 'bold',

matplotlib.rc('font', **font)

# 2013
labels = ['Households', 'Agriculture', 'Industry', 'Services', 'Traffic']
cons = [18333, 986, 19029, 15855, 4770]
explode = [0.15, 0, 0, 0, 0]
share = [ float(x) / np.sum(cons) * 100 for x in cons ]
print(share)
# colors = ['blue', 'green', 'red', 'cyan', 'gray', 'magenta', 'yellow', 'yellowgreen', 'black', 'white']
fig = figure(num=None, figsize=(9, 6), dpi=80, facecolor='w', edgecolor='k')
fig = plt.pie(cons, labels=labels, startangle=90, explode=explode, autopct='%1.0f%%')

plt.axis('equal')
# plt.title('Ground truth consumption (75 days)')
plt.savefig("electricity_consumption_2013.eps", format='eps')
plt.show()
