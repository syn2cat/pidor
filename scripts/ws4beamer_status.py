#!/usr/bin/env python2.7
import requests
import flask
import re
import os

with open( os.path.dirname(os.path.realpath(__file__)) + "/beamerip.txt", 'r') as f:
    beamerip = f.readline()

app = flask.Flask(__name__)

@app.route("/")
def status():
    try:
      res = requests.get("http://"+beamerip+"/tgi/return.tgi?query=info", timeout=1)
      if "NG" in res.content:
        return "0"
      reg_res = re.findall(b"<info>([^<]*)</info>", res.content)
      status = str(reg_res[0][30:32])
      if status == "01":
        return "1"
    except Exception as e:
      print(e)
    return "0"

if __name__ == "__main__":
    app.run("0.0.0.0", 5042)
