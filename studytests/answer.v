module main

import vweb
import time
import crypto.md5

struct Answer {
	id i64 [primary; sql; serial]
	user_id i64
	question_id i64
	answ string
}

['/add_answer'; post]
pub fn (mut app App) add_answer(user_password string, code_word string, question_id int, user_answer string) vweb.Result{
	
	mut password := user_password
	if code_word != '' {
		password = md5.hexhash(user_password + code_word)
	}
	user := sql app.db {
		select from User where password == password limit 1
	}

	if user.id == 0 {
		return app.text('')
	}

	question := sql app.db{
		select from Question where id == question_id
	}

	test := sql app.db {
		select from Test where id == user.test_id
	}

	if question.test_id != user.test_id {
		return app.text('')
	}

	if test.test_type == "FORM" && !user.crypted {
		return app.text('')
	}

	has_answer := sql app.db {
		select from Answer where user_id == user.id && question_id == question_id limit 1
	}
	if has_answer.id != 0 {
		return app.text('')
	}

	answer := Answer{
		user_id: user.id
		question_id: question_id
		answ: user_answer
	}

	sql app.db {
		insert answer into Answer
	}

	all_answers := sql app.db {
		select from Answer where user_id == user.id
	}

	all_questions := sql app.db {
		select from Question where test_id == user.test_id
	}

	if all_answers.len == all_questions.len {
		sql app.db {
			update User set done = true where id == user.id
		}
		now := time.now().ddmmy()
		sql app.db {
			update User set done_date = now where id == user.id
		}
	}

	return app.text('OK')
}