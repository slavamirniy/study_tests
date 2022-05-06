module main

struct QuestionAnswer {
	id i64 [primary; sql; serial]
	question_id i64
	answer string
}

pub fn (mut app App) get_answers_for_question(question_id i64) []string {
	q_answers := sql app.db {
		select from QuestionAnswer where question_id == question_id
	}
	mut answers := []string{}
	for a in q_answers {
		answers << a.answer
	}
	return answers
}

pub fn (mut app App) delete_answers_for_question(question_id i64) {
	sql app.db {
		delete from QuestionAnswer where question_id == question_id
	}
}

pub fn (mut app App) add_question_answers(question_id i64, answers []string) {
	for a in answers {
		new_answer := QuestionAnswer{
			question_id: question_id
			answer: a
		}
		sql app.db {
			insert new_answer into QuestionAnswer
		}
	}
}