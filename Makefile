SHELL := /bin/bash

.PHONY: help install start dev clean

help:
	@echo "Targets:"
	@echo "  make install   Install dependencies"
	@echo "  make start     Start the app (npm start)"
	@echo "  make dev       Start with auto-reload (nodemon)"
	@echo "  make clean     Remove node_modules"

install:
	npm install

start:
	npm start

dev:
	npx nodemon app.js

clean:
	rm -rf node_modules
