"""Train: python -m model.train path/to/merged.csv  (needs a 'label' column, 1=attack)."""
import json
import sys

import lightgbm as lgb
import pandas as pd

from .lgbm import FEATURES_PATH, MODEL_PATH

df = pd.read_csv(sys.argv[1])
y = df.pop("label")
X = df.select_dtypes("number")
m = lgb.LGBMClassifier(n_estimators=200, learning_rate=0.05).fit(X, y)
m.booster_.save_model(MODEL_PATH)
json.dump(list(X.columns), open(FEATURES_PATH, "w"))
print("saved", MODEL_PATH, len(X.columns), "features")
