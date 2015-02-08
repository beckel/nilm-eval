from pylab import *
import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv('actual.csv')
labels = df['label']
cons = df['consumption']
share = df['share'] 
colors = ['blue', 'green', 'red', 'cyan', 'gray', 'magenta', 'yellow', 'yellowgreen', 'black', 'white']
new_labels = []
for i in range(0,10):
#    new_labels.append(labels[i] + ' \n(' + str(cons[i]) + ' kWh, ' + str(share[i]*100) + '%)')
    new_labels.append(labels[i] + '\n' + str(cons[i]) + ' kWh' + '\n' + str(share[i]*100) + '%')
fig = plt.pie(share, labels=new_labels, startangle=0, colors=colors)
#plt.pie(sizes, explode=explode, labels=labels, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)
plt.axis('equal')
# plt.title('Ground truth consumption (75 days)')
plt.savefig("actual.eps", format='eps')
plt.show()

# plt.figure().patch.set_facecolor('white')

df = pd.read_csv('inferred.csv')
labels = df['label']
cons = df['consumption']
share = df['share']
colors = ['blue', 'green', 'red', 'cyan', 'gray', 'magenta', 'yellow', 'yellowgreen', 'black', 'brown', 'white']
new_labels = []
for i in range(0,11):
#    new_labels.append(labels[i] + ' \n(' + str(cons[i]) + ' kWh, ' + str(share[i]*100) + '%)')
    new_labels.append(labels[i] + '\n' + str(cons[i]) + ' kWh' + '\n' + str(share[i]*100) + '%')
plt.pie(share, labels=new_labels, startangle=0, colors=colors)
#plt.pie(sizes, explode=explode, labels=labels, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)
plt.axis('equal')
# plt.title('Inferred consumption (75 days)')
plt.savefig("inferred.eps", format='eps')
plt.show()