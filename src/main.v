module main

import picoev
import picohttpparser
import net.http
import db.pg
import net.urllib
import time

const (
	port = 8080
)

struct App {
	db pg.DB
}

struct Response {
	status_code http.Status = http.Status.not_found
	headers     map[string]string
	body        string
}

[inline]
fn (a App) get_count() &Response {
	count := sql a.db {
		select count from People
	} or { 0 }

	return &Response{
		status_code: http.Status.ok
		body: count.str()
	}
}

[inline]
fn (a App) find_by_nickname(nick string) []People {
	people_list := sql a.db {
		select from People where nickname == nick limit 1
	} or { []People{} }

	return people_list
}

[inline]
fn (a App) find_by_id(people_id string) ?People {
	people_list := sql a.db {
		select from People where id == people_id limit 1
	} or { []People{} }

	return if people_list.len > 0 { people_list.first() } else { none }
}

[inline]
fn (a App) save_people(people People) ! {
	sql a.db {
		insert people into People
	} or { return error('failed to save: ${people.str()}') }
}

[inline]
fn (a App) create_person(body string) &Response {
	new_people := People.from_json(body) or {
		return &Response{
			status_code: http.Status.unprocessable_entity
		}
	}

	if a.find_by_nickname(new_people.nickname).len > 0 {
		return &Response{
			status_code: http.Status.unprocessable_entity
		}
	}

	a.save_people(new_people) or {
		eprintln(err)
		return &Response{
			status_code: http.Status.bad_request
		}
	}

	return &Response{
		status_code: http.Status.created
		headers: {
			'Location': '/pessoas/${new_people.id}'
		}
	}
}

[inline]
fn (a App) search(query string) &Response {
	if query == '' {
		return &Response{
			status_code: http.Status.bad_request
		}
	}

	person_list := sql a.db {
		select from People where search like '%${query.to_lower()}%' limit 50
	} or { []People{} }

	return &Response{
		status_code: http.Status.ok
		body: person_list.to_json()
	}
}

[inline]
fn (a App) get_person(id string) &Response {
	people := a.find_by_id(id) or { return &Response{} }

	return &Response{
		status_code: http.Status.ok
		body: people.to_json()
	}
}

[inline]
fn (a App) handler(req picohttpparser.Request) &Response {
	people_resource := req.path.starts_with('/pessoas')

	if req.method == 'POST' && people_resource {
		return a.create_person(req.body)
	}

	if req.method == 'GET' {
		if req.path == '/pessoas' {
			return &Response{
				status_code: http.Status.bad_request
			}
		}

		if people_resource {
			url := urllib.parse(req.path) or { urllib.URL{} }
			if term := get_serch_term(url.raw_query, 't') {
				return a.search(term)
			}

			resource_id := url.path.split('/').last()
			if resource_id != '' {
				return a.get_person(resource_id)
			}
		}

		if req.path.starts_with('/contagem-pessoas') {
			return a.get_count()
		}
	}

	return &Response{
		status_code: http.Status.bad_request
	}
}

fn (a App) callback(_ voidptr, req picohttpparser.Request, mut res picohttpparser.Response) {
	start := time.new_stopwatch()

	response := a.handler(req)

	duration := start.elapsed().milliseconds()
	if duration > 1000 {
		println('request took: ${duration}')
	}


	res.write_string('HTTP/1.1 ${int(response.status_code)} ${response.status_code.str()}\r\n')
	for key, value in response.headers {
		res.header(key, value)
	}
	res.body(response.body)
	res.end()
}

fn main() {

	mut app := &App{
		db: pg.connect(pg.Config{
			host: 'database'
			port: 5432
			user: 'dev'
			password: 'dev'
			dbname: 'rinha'
		})!
	}

	mut server := picoev.new(
		port: port
		cb: app.callback
	)

	server.serve()
}

[inline]
fn get_serch_term(query_str string, term string) ?string {
	if query := urllib.parse_query(query_str) {
		if value := query.get(term) {
			return value
		}
	}

	return none
}
