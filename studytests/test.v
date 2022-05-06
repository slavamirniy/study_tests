module main

import vweb
import rand

struct Test {
	id i64 [primary; sql; serial]
	name string
	password string
	test_type string
}

struct TestReturn {
	name string
	test_type string
	users []UserReturn
}

['/create_test'; post]
pub fn (mut app App) create_test(test_name string, test_type string) vweb.Result {
	if test_name == '' {
		return app.text('')
	}

	test_types := ['FORM', 'TEST']
	if test_type == '' || !(test_type in test_types) {
		return app.text('')
	}
	
	code := rand.hex(45)
	test := Test {
		name: test_name
		password: code
		test_type: test_type
	}

	sql app.db {
		insert test into Test
	}

	return app.text(code)
}

['/get_test'; post]
pub fn (mut app App) users(test_password string) vweb.Result {
	test := sql app.db {
		select from Test where password == test_password limit 1
	}

	if test.id == 0 {
		return app.text('')
	}

	users := app.get_users(test.id)

	return app.json(
		TestReturn {
			name: test.name
			test_type: test.test_type
			users: users
		}
	)
}