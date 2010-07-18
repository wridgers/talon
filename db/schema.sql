create table quotes (
	id		integer primary key,
	nick		text,
	quote		text,
	vote		integer,
	addby		text,
	addhost		text
);

create table users (
	id		integer primary key,
	nick		text,
	password	text,
	hostmask	text,
	title		text,
	email		text,
	automode	text,
	isbanned	integer default 0,
	isadmin		integer default 0,
	isgod		integer default 0
);

create table logs (
	id		integer primary key,
	timestamp	text,
	nick		text,
	host		text,
	chan		text,
	message		text
);

create table words (
	id		integer primary key,
	word		text,
	nick		text,
	count		integer default 0
);
