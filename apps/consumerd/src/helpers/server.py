from flask import Flask, request
app = Flask(__name__)

@app.route("/",methods = ["GET","POST"])
def hello():
    if request.method == 'POST':
        return "ok"
    else:
        return str({"shit":"fuck"})
        

if __name__ == "__main__":
    app.debug = True
    app.run()
