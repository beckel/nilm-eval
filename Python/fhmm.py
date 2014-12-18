from collections import OrderedDict
import sys
import itertools

import numpy as np

from sklearn import hmm

class Fhmm(object):
    
    def __init__(self):
        self.model = {}
        self.appliances = {}
        
    def train(self, appliances):

        for appliance in appliances:
            
            # print(int(appliance['id']))
            # print(appliance['name'])
            # print(appliance['plug_data_training'])
            # print(type(appliance['plug_data_training']))
            # print(int(appliance['num_states']))
            
            num_states = int(appliance['num_states'])
            name = appliance['name']
            
            X = np.array(appliance['plug_data_training'])
            X = np.atleast_2d(X)
            X = np.transpose(X)
            
            print("Fitting appliance: " + name + " ...")
            learnt_model = hmm.GaussianHMM(num_states, "full")
            learnt_model.fit([X])
            self.model[name] = learnt_model
            # print(learnt_model.covars_)
            # print(np.shape(learnt_model.covars_))

        self.appliances = appliances
        
        return    


    def disaggregate(self, meter_data):
        
        # Sort model and create combined model
        print("starting disaggregation")
        model_sorted = OrderedDict()
        means_orig = OrderedDict()
        
        for appliance in [ x['name'] for x in self.appliances]:
            print("appliance: " + appliance)
            means_orig[appliance] = self.model[appliance].means_
            startprob, means, covars, transmat = sort_learnt_parameters(self.model[appliance].startprob_, self.model[appliance].means_, self.model[appliance].covars_, self.model[appliance].transmat_) 
            model_sorted[appliance] = hmm.GaussianHMM(startprob.size, "full", startprob, transmat)
            model_sorted[appliance].means_ = means
            model_sorted[appliance].covars_ = covars
        combined_model = create_combined_hmm(model_sorted)
        
        print("Disaggregating ...")
        X = np.array(meter_data)
        X = np.atleast_2d(X)
        X = np.transpose(X)
                    
        # X = np.transpose(np.atleast_2d(meter_data))
        print(np.shape(X))
        learnt_states = combined_model.predict(X)
        print("... done")
        
        [decoded_states, decoded_power] = decode_hmm(len(learnt_states), means_orig, [appliance for appliance in self.model], learnt_states)
        
        return [decoded_states, decoded_power]
        
        
        
        
        
        
        
            
            
################################################################
# FUNCTIONS TO SORT HMM PARAMETERS ACCORDING TO SEQUENCE GIVEN BY MEANS FOR EACH APPLIANCE
################################################################
            
def sort_learnt_parameters(startprob, means, covars, transmat):
    mapping = return_sorting_mapping(means)
    means_new = np.sort(means, axis = 0)
    startprob_new = sort_startprob(mapping, startprob)
    covars_new = sort_covars(mapping, covars)
    transmat_new = sort_transition_matrix(mapping, transmat)
    assert np.shape(means_new) == np.shape(means)
    assert np.shape(startprob_new) == np.shape(startprob)
    assert np.shape(transmat_new) == np.shape(transmat)
    return [startprob_new, means_new, covars_new, transmat_new]

def return_sorting_mapping(means):
    idx = np.argsort(np.transpose(means))
    i = 0
    mapping = {}
    for x in idx[0]:
        mapping[i] = x
        i = i+1
    return mapping

def sort_startprob(mapping, startprob):
    """ Sort the startprob according to power means; as returned by mapping
    """
    num_elements = len(startprob)
    new_startprob = np.zeros(num_elements)
    for i in xrange(len(startprob)):
        new_startprob[i] = startprob[mapping[i]]
    return new_startprob

def sort_covars(mapping, covars):
    num_elements = len(covars)
    new_covars = np.zeros_like(covars)
    for i in xrange(len(covars)):
        new_covars[i] = covars[mapping[i]]
    return new_covars
    

def sort_transition_matrix(mapping, A):
    """ Sorts the transition matrix according to power means; as returned by mapping
    """
    num_elements = len(A)
    A_new = np.zeros((num_elements, num_elements))
    for i in range(num_elements):
        for j in range(num_elements):
            A_new[i,j] = A[mapping[i], mapping[j]]   
    return A_new

################################################################
# FUNCTIONS TO CREATE HMM BASED ON (EXPONENTIAL) COMBINATIONS OF ORIGINAL HMM PARAMETERS 
################################################################

def create_combined_hmm(model):
    list_pi = [model[appliance].startprob_ for appliance in model]
    list_A = [model[appliance].transmat_ for appliance in model]
    list_means=[model[appliance].means_.flatten().tolist() for appliance in model]
    
    pi_combined=compute_pi_fhmm(list_pi)
    A_combined=compute_A_fhmm(list_A)
    [mean_combined, cov_combined]=compute_means_fhmm(list_means)

    combined_model=hmm.GaussianHMM(n_components=len(pi_combined),covariance_type='full', startprob=pi_combined, transmat=A_combined)
    combined_model.covars_=cov_combined
    combined_model.means_=mean_combined
    return combined_model
    
def compute_pi_fhmm(list_pi):
    '''
    Input: list_pi: List of PI's of individual learnt HMMs
    Output: Combined Pi for the FHMM
    '''
    result=list_pi[0]
    for i in range(len(list_pi)-1):
        result=np.kron(result,list_pi[i+1])
    return result

def compute_A_fhmm(list_A):
    '''
    Input: list_pi: List of A's of individual learnt HMMs
    Output: Combined A for the FHMM
    '''
    result=list_A[0]
    for i in range(len(list_A)-1):
        result=np.kron(result,list_A[i+1])
    return result

def compute_means_fhmm(list_means):  
    '''
    Returns [mu, sigma]
    '''
    states_combination=list(itertools.product(*list_means))
    num_combinations=len(states_combination)
    means_stacked=np.array([sum(x) for x in states_combination])
    means=np.reshape(means_stacked,(num_combinations,1)) 
    cov=np.tile(5*np.identity(1), (num_combinations, 1, 1))
    return [means, cov]     
    
########################################################
# DECODE HMM STATE SEQUENCE TO DECODED STATES AND POWER PER APPLIANCE
########################################################

def decode_hmm(length_sequence, centroids_orig, appliance_list, states):
    '''
    Decodes the HMM state sequence
    '''

    power_states_dict={}    
    hmm_states={}
    hmm_power={}
    total_num_combinations=1
    for appliance in appliance_list:
        total_num_combinations*=len(centroids_orig[appliance])  

    for appliance in appliance_list:
        hmm_states[appliance]=np.zeros(length_sequence,dtype=np.int)
        hmm_power[appliance]=np.zeros(length_sequence)

    for i in range(length_sequence):
        factor=total_num_combinations
        for appliance in appliance_list:
            #assuming integer division (will cause errors in Python 3x)
            factor=factor//len(centroids_orig[appliance])

            temp=int(states[i])/factor
            hmm_states[appliance][i]=temp%len(centroids_orig[appliance])
            centroid_sorted = np.sort(centroids_orig[appliance], axis = 0)
            hmm_power[appliance][i]=centroid_sorted[hmm_states[appliance][i]]

    return [hmm_states,hmm_power]