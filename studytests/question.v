module main

import vweb
import json

struct Question {
	id i64 [primary; sql; serial]
	test_id i64
	kind int
	content string
	right_answ string
}

struct QuestionAnswersReturn {
	id i64 [primary; sql; serial]
	kind int
	content string
	right_answ string
	answers []string
}

struct QuestionReturn {
	id i64
	kind int
	content string
	answers []string
}

pub fn (mut app App) to_question_return(q Question) QuestionReturn {
	answers := app.get_answers_for_question(q.id) 
	return QuestionReturn {
		kind: q.kind
		content: q.content
		answers: answers
		id: q.id
	}
}

pub fn (mut app App) to_question_answers_return(q Question) QuestionAnswersReturn {
	answers := app.get_answers_for_question(q.id) 
	return QuestionAnswersReturn {
		kind: q.kind
		content: q.content
		answers: answers
		right_answ: q.right_answ
		id: q.id
	}
}

['/add_question'; post]
pub fn (mut app App) add_question(test_password string, kind int, content string, json_answers string, right_answ string) vweb.Result {
	// получаем тест
	test := sql app.db {
		select from Test where password == test_password limit 1
	}

	if test.id == 0 {
		return app.text('')
	}

	answers := json.decode([]string, json_answers) or {
		return app.text('')
	}

	q := Question {
		test_id: test.id
		kind: kind
		content: content
		right_answ: right_answ
	}

	sql app.db {
		insert q into Question
	}

	new_question_id := app.db.last_insert_rowid()
	app.add_question_answers(new_question_id, answers)

	return app.text(new_question_id.str())
}

['/delete_question'; post]
pub fn (mut app App) delete_question(test_password string, question_id int) vweb.Result {
	// получаем тест
	test := sql app.db {
		select from Test where password == test_password limit 1
	}

	question := sql app.db {
		select from Question where id == question_id
	}

	if test.id == 0 || question.test_id != test.id {
		return app.text('')
	}

	sql app.db {
		delete from Answer where question_id == question_id
	}

	sql app.db {
		delete from Question where id == question_id
	}

	app.delete_answers_for_question(question.id)

	return app.text('OK')
}

['/get_questions'; post]
pub fn (mut app App) get_questions(test_password string) vweb.Result {
	// получаем тест
	test := sql app.db {
		select from Test where password == test_password limit 1
	}

	if test.id == 0 {
		return app.text('')
	}

	questions := sql app.db{
		select from Question where test_id == test.id
	}

	mut questions_with_answers := []QuestionAnswersReturn{}
	for q in questions {
		questions_with_answers << app.to_question_answers_return(q)
	}
	return app.json(questions_with_answers)
}