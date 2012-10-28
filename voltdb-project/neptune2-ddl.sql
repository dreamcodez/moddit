CREATE TABLE sequences (
  name VARCHAR(64) NOT NULL,
  val  BIGINT      NOT NULL,
  PRIMARY KEY(name)
);

CREATE TABLE users (
  id    BIGINT NOT NULL,
  login VARCHAR(32) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE comments (
  id      BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  post_id BIGINT,
  body    VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE posts ( 
  id      BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  title   VARCHAR(64) NOT NULL,
  body    VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE pages (
  uri  VARCHAR(1024),
  json VARCHAR(1048576),
  PRIMARY KEY (uri)
);

