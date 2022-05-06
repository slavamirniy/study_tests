module main

import sqlite
import vweb

struct App {
	vweb.Context
pub mut:
	db sqlite.DB
}

fn main() {
	mut app := App {
		db: sqlite.connect('blog.db') or { panic(err) }
	}

	sql app.db {
		create table Test
		create table Question
		create table Answer
		create table User
		create table QuestionAnswer
	}

	vweb.run(app,8080)
}

fn (mut app App) init_db() {
	sql app.db {
		create table Test
		create table Question
		create table Answer
		create table User
	}

	test := Test {
		name: "Test test"
		password: "qwertyuiop"
	}

	sql app.db {
		insert test into Test
	}
}

['/testeditor']
fn (app &App) testeditor() vweb.Result {
	css := "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"
	js := "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"
	return $vweb.html()
}

['/test']
fn (app &App) test() vweb.Result {
	css := "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"
	js := "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"
	return $vweb.html()
}