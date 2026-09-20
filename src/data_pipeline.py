#!/usr/bin/env python
# coding: utf-8

# In[1]:


#code 1 - defining and setting up logging message - its format -> Setup, Logging, and Data Ingestion
import os
import pandas as pd
import numpy as np
import logging


# In[2]:


logging.basicConfig(
    level = logging.INFO,
    format = '%(asctime)s - %(levelname)s - %(message)s'
)


# In[3]:


raw_df = pd.read_csv("WA_Fn-UseC_-Telco-Customer-Churn.csv")  #always have extension in the file name


# In[4]:


logging.info(f"Raw data loaded successfully. The total rows: {len(raw_df)} and total columns: {len(raw_df.columns)}")


# In[5]:


#Cell 2: Defensive Data Quality Validation
def validate_data(df: pd.DataFrame) -> None:
    logging.info("Starting data validation")

    #1. primary key uniqueness check
    if not df['customerID'].is_unique():
        duplicates = df['customerID'].duplicated().sum()
        raise ValueError(f"The customer ID is not unique and has {duplicates} duplicated value")

    #2. All required columns are present or not
    required_col = ['customerID', 'tenure', 'monthlycharges', 'totalcharges', 'contract', 'churn']
    missing = required_col - set(df.columns)
    if missing:
        raise KeyError(f"There are {missing} required columns missing in the table")

    #3. domain logic check
    if (df['tenure'] < 0).any():          #.any() is for even atleast 1 value is true - then its an error
        raise ValueError("Tenure cannot be negative!")
    if (df['monthlycharges'] <= 0).any():
        raise ValueError("Monthly charges can't be negative or 0 as there will be some monthly charge if a customer with even 0 tenure - signs up")
    if (df['totalcharges'] < 0).any():
        raise ValueError("Total charges can't be negative")

    logging.info("Data Validation finished successfully")
    validate_data(raw_df)


# In[6]:


#Cell 3: Data Transformation, Feature Engineering, & File Export
def transform_data(df: pd.DataFrame) -> pd.DataFrame:
    logging.info("Starting with transformation/ cleaning and EDA process")
    data = df.copy()

    #1. lower case of all col names
    data.columns = [col.strip().lower().replace(' ', '_') for col in data.columns]

    #2. changing datatype of total charges and replacing null values with 0.0
    data['totalcharges'] = pd.to_numeric(data['totalcharges'].astype(str).str.strip() , errors = 'coerce')
    data['totalcharges'] = data['totalcharges'].fillna(0.0)

    #3. tenure bins
    bins = [-1, 12, 24, 48, 60, 100]
    labels = ['0-1 years', '1-2 years', '2-4 years', '4-5 years', '5+ years']
    data['tenure_bins_cohort'] = pd.cut(data['tenure'],bins = bins, labels = labels)

    #4. churn risk score calculate
    data['churn_risk_score']=(
        (data['contract'] == 'Month-to-Month').astype(int)*35 + 
        (data['paymentmethod'] == 'Electronic check').astype(int)*15 +
        (data['tenure'] <= 12).astype(int)*25 +
        (data['internetservice'] == 'Fiber optic').astype(int)*25
    )

    #5. churn yes = 1 - columns
    data['churn_customers'] = np.where(data['churn'] == 'Yes', 1,0)

    # 6. Monthly Financial Risk Exposure ($)
    data['monthly_revenue_at_risk'] = data['monthlycharges'] * data['churn_customers']


    logging.info("transformation/ cleaning and EDA process is successful")
    return data

Output_path = "telco_churn_processed.csv"
final_data = transform_data(raw_df)

final_data.to_csv(Output_path, index = False)
logging.info(f"Cleaned dataset successfully exported to: '{Output_path}'")


final_data[['customerid', 'tenure_bins_cohort', 'churn_risk_score', 'monthly_revenue_at_risk', 'churn_customers']].head()



# In[7]:


final_data[['customerid', 'tenure_bins_cohort', 'churn_risk_score', 'monthly_revenue_at_risk', 'churn_customers']].head()


# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:




