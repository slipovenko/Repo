SET search_path TO medicforum; 
CREATE TABLE post (
      id INTEGER PRIMARY KEY,
      autor varchar NOT NULL DEFAULT '',
      title varchar NOT NULL DEFAULT '',
      alt_name varchar NOT NULL DEFAULT ''
);

 CREATE TABLE keywords (
      id integer primary key,
      name varchar UNIQUE
);

 CREATE TABLE category (
      id integer primary key,
      parentid integer NOT NULL DEFAULT '0',
      name varchar NOT NULL DEFAULT '',
      alt_name varchar NOT NULL DEFAULT '',
      descr varchar NOT NULL DEFAULT ''
);

 CREATE TABLE post_category (
      post_id integer NOT NULL DEFAULT '0',
      category_id integer NOT NULL DEFAULT '0',
      PRIMARY KEY (post_id,category_id)
);

CREATE TABLE post_keywords(
      post_id integer NOT NULL DEFAULT '0',
      keyword_id integer NOT NULL DEFAULT '0',
      PRIMARY KEY (post_id,keyword_id)
);
