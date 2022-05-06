module main

import vweb
import rand
import crypto.md5

struct User {
	id i64 [primary; sql; serial]
	test_id i64
	name string
	password string
	done_date string
	done bool
	crypted bool
	registered bool
}

struct UserReturn {
	name string
	done_date string
	done bool
	password string
	crypted bool
	answers []UserAnswer
	good_count int
}

struct UserAnswer {
	question_id i64
	content string
	right_answ string
	user_answ string
}

struct AuthReturn {
	name string
	done bool
	test_name string
	register_needed bool
	auth_needed bool
	questions []QuestionReturn
}

// Получает список проходящих по паролю теста
pub fn (mut app App) get_users(test_id i64) []UserReturn {
	// получаем тест
	test := sql app.db {
		select from Test where id == test_id limit 1
	}
	
	// получаем проходящих
	users := sql app.db {
		select from User where test_id == test.id
	}

	// получаем вопросы теста
	questions := sql app.db {
		select from Question where test_id == test.id
	}

	// инициализируем массив проходящих для возврата
	mut users_return := []UserReturn{}
	// проходим по каждому проходящему данного теста
	for u in users {
		// переменная, ответственная за кол-во верных ответов
		mut user_good_count := 0
		// массив ответов проходящего для возврата
		mut user_answers_return := []UserAnswer{}
		// получаем ответы проходящего из базы
		user_answers := sql app.db {
			select from Answer where user_id == u.id
		}

		if user_answers.len == questions.len {
			// проходим по каждому вопросу
			for quest in questions {
				// находим ответ проходящего на соответствующий вопрос
				mut answer := user_answers.filter(it.question_id == quest.id)[0]
				// добавляем необходимы данные для возврата
				user_answer := UserAnswer{
					content: quest.content
					right_answ: quest.right_answ
					user_answ: answer.answ
					question_id: quest.id
				}
				// увеличиваем кол-во верных ответов
				if answer.answ == quest.right_answ {
					user_good_count++
				}
				// добавляем ответы проходящего в возврат
				user_answers_return << user_answer
			}
		}
		// добавляем данные о проходящем в возврат
		mut return_password := u.password
		if test.test_type == "FORM" && u.crypted { return_password = '' }
		user_return := UserReturn {
			name: u.name
			done_date: u.done_date
			done: u.done
			crypted: u.crypted
			password: return_password
			answers: user_answers_return
			good_count: user_good_count
		}

		// добавляем проходящего в массив
		users_return << user_return
	}

	return users_return
}

// Добавляет проходящего по паролю теста
['/add_user'; post]
pub fn (mut app App) add_user(test_password string, user_name string) vweb.Result {
	// получаем тест
	test := sql app.db {
		select from Test where password == test_password limit 1
	}
	// если такого теста нет, то возвращаем пустую строку
	if test.id == 0 || user_name == '' {
		return app.text('')
	}

	// генерируем пароль для пользователя (30 случайных символов)
	code := rand.hex(30)
	println(code)

	user := User {
		test_id: test.id
		name: user_name
		password: code
	}
	// добавялем пользотваеля в базу
	sql app.db {
		insert user into User
	}

	return app.text(code)
}

// Авторизация по пароля проходящего
['/auth'; post]
pub fn (mut app App) auth(user_password string, code_word string) vweb.Result {
	// получаем проходящего по паролю

	mut password := user_password
	if code_word != '' {
		password = md5.hexhash(user_password + code_word)
	}

	user := sql app.db {
		select from User where password == password limit 1
	}

	// если проходящий не найден
	if user.id == 0 {
		return app.text('')
	}	

	// получаем список вопросов
	questions := sql app.db {
		select from Question where test_id == user.test_id
	}

	test := sql app.db {
		select from Test where id == user.test_id
	}

	// преобразовываем его, удаляя лишние данные (верный ответ, айди и проч.) и те вопросы, на которые был дан ответ
	answers := sql app.db {
		select from Answer where user_id == user.id
	}
	mut questions_return := []QuestionReturn{}
	if (test.test_type == "TEST") || (test.test_type == "FORM" && user.crypted) {
		for q in questions {
			if answers.filter(it.question_id == q.id).len == 0 {
				questions_return << app.to_question_return(q)
			}
		}
	}

	return app.json(AuthReturn {
		name: user.name
		done: user.done
		test_name: test.name
		register_needed: test.test_type == "FORM" && !user.crypted && !user.registered
		auth_needed: test.test_type == "FORM" && user.registered
		questions: questions_return
	})
}

['/register'; post]
pub fn (mut app App) register(user_password string, code_word string) vweb.Result {
	user := sql app.db {
		select from User where password == user_password limit 1
	}

	if user.id == 0 {
		return app.text('')
	}

	if user.registered {
		return app.text('')
	}

	if code_word == '' {
		return app.text('')
	}

	test := sql app.db {
		select from Test where id == user.test_id
	}

	if test.test_type != "FORM" {
		return app.text('')
	}

	new_password := md5.hexhash(user_password + code_word)

	new_user := User {
		test_id: test.id
		name: user.name
		password: new_password
		crypted: true
		registered: true
	}

	sql app.db {
		insert new_user into User
	}

	sql app.db {
		update User set registered = true where id == user.id
	}

	return app.text('OK')

}