CREATE DATABASE CalendarWebapp;
USE CalendarWebapp;

CREATE TABLE users (
  id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username CHAR(30) NOT NULL UNIQUE,
  passwordHash CHAR(92) NOT NULL,
  privilege TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE events (
  id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  begin DATE NOT NULL,
  end DATE,
  name CHAR(128) NOT NULL,
  description TEXT NOT NULL,
  type TINYINT UNSIGNED NOT NULL,
  shout BOOLEAN NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO users (username, passwordHash, privilege) VALUES ('foo',
'$5$eGohWUmw9yyiTqG7kti1MmT/jR52raEVlYuHQJa/sYk=$ucI+vTQq38Rr5RUAatd4Om0Dy9fuF0oKgkuVCuXSnxc=', 2);
