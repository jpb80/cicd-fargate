#!/usr/bin/env python
# coding=utf-8

from flask import Flask
from flask import request
from flask import jsonify

app = Flask(__name__)


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "OK"}), 200


@app.route("/", methods=["GET"])
def greeting():
    return jsonify({"message":"Hello World!"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
