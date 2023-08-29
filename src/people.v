module main

import json
import rand
import time

[table: 'people']
pub struct People {
	id        string [default: 'gen_random_uuid()'; primary; sql_type: 'uuid']
	name      string [nonnull; sql_type: 'VARCHAR(100)']
	nickname  string [nonnull; sql_type: 'VARCHAR(32)'; unique]
	birthdate string [nonnull; sql_type: 'CHAR(10)']
	stack     string
	search    string
}

fn People.from_json(json_str string) !&People {
	return PeopleDto.from_json(json_str)!.to_people()
}

fn (p People) to_dto() &PeopleDto {
	return &PeopleDto{
		id: p.id
		nickname: p.nickname
		name: p.name
		birthdate: p.birthdate.str()
		stack: p.stack.split(',')
	}
}

fn (p People) to_json() string {
	return p.to_dto().to_json()
}

fn (p []People) to_json() string {
	dto_list := p.map(*it.to_dto())
	return json.encode(dto_list)
}

pub struct PeopleDto {
	nickname  string   [json: apelido; reqired]
	name      string   [json: nome; required]
	birthdate string   [json: nascimento; required]
	stack     []string
mut:
	id string
}

fn PeopleDto.from_json(json_str string) !&PeopleDto {
	mut dto := json.decode(PeopleDto, json_str)!
	time.parse_format(dto.birthdate, 'YYYY-MM-DD') or {
		return error('Invalid date: ${dto.birthdate}')
	}
	if dto.nickname.len > 32 {
		return error('invalid nickname length')
	}
	if dto.name.len > 100 {
		return error('invalid name length')
	}
	dto.id = rand.uuid_v4()
	return &dto
}

fn (p PeopleDto) to_json() string {
	return json.encode(p)
}

fn (p PeopleDto) to_people() &People {
	return &People{
		id: p.id
		nickname: p.nickname
		name: p.name
		birthdate: p.birthdate
		stack: p.stack.join(',')
		search: '${p.nickname}${p.name}${p.stack.join('')}'.to_lower()
	}
}
